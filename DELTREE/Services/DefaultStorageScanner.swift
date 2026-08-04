import Foundation

struct DefaultStorageScanner: StorageScanning, @unchecked Sendable {
    private let fileManager: FileManager
    private let fileSizeScanner: any FileSizeScanning
    private let simctlClient: any SimctlClient
    private let codexSessionScanner: any CodexSessionScanning
    private let processSampler: any ProcessSampling
    private let openFileChecker: any OpenFileChecking
    private let attributionTracker: any AttributionTracking
    private let safetyPolicy: any SafetyClassifying
    private let rootCatalog: StorageRootCatalog

    init(
        rootCatalog: StorageRootCatalog = .live(),
        fileManager: FileManager = .default,
        fileSizeScanner: any FileSizeScanning = LiveFileSizeScanner(),
        simctlClient: any SimctlClient = LiveSimctlClient(),
        codexSessionScanner: any CodexSessionScanning = CodexThreadCatalogReader(),
        processSampler: any ProcessSampling = LiveProcessSampler(),
        openFileChecker: any OpenFileChecking = LiveLsofOpenFileChecker(),
        attributionTracker: any AttributionTracking = LiveAttributionTracker(),
        safetyPolicy: any SafetyClassifying = DefaultSafetyPolicy())
    {
        self.fileManager = fileManager
        self.fileSizeScanner = fileSizeScanner
        self.simctlClient = simctlClient
        self.codexSessionScanner = codexSessionScanner
        self.processSampler = processSampler
        self.openFileChecker = openFileChecker
        self.attributionTracker = attributionTracker
        self.safetyPolicy = safetyPolicy
        self.rootCatalog = rootCatalog
    }

    @concurrent func scan(configuration: StorageScanConfiguration, now: Date = Date()) async -> StorageSnapshot {
        async let devices = simctlClient.devices()
        async let sessions = codexSessionScanner.sessions(now: now)
        async let processes = processSampler.sample()

        let context = await DomainScanContext(
            fileManager: fileManager,
            fileSizeScanner: fileSizeScanner,
            simctlDevices: devices,
            codexSessions: sessions,
            processSnapshot: processes,
            attributionTracker: attributionTracker,
            configuration: configuration,
            now: now)

        let domainScanners = makeDomainScanners(configuration: configuration)
        var items: [StorageItem] = []
        var missingPaths: [String] = []
        var unreadablePaths: [String] = []

        for scanner in domainScanners {
            if Task.isCancelled {
                break
            }
            let result = await scanner.scan(context: context)
            items.append(contentsOf: result.items)
            missingPaths.append(contentsOf: result.missingPaths)
            unreadablePaths.append(contentsOf: result.unreadablePaths)
        }

        let classifiedItems = await classify(items: deduplicated(items), configuration: configuration, now: now)

        return StorageSnapshot(
            capturedAt: now,
            items: classifiedItems.sorted { lhs, rhs in
                if lhs.bytes == rhs.bytes {
                    return lhs.displayName.localizedStandardCompare(rhs.displayName) == .orderedAscending
                }
                return lhs.bytes > rhs.bytes
            },
            missingPaths: unique(missingPaths),
            unreadablePaths: unique(unreadablePaths))
    }

    private func makeDomainScanners(configuration: StorageScanConfiguration) -> [any DomainScanning] {
        let roots = rootCatalog.roots(configuration: configuration)
        return [
            CodexWorkspaceDomainScanner(
                domain: .codexHome,
                kind: .codexData,
                roots: roots[.codexHome] ?? [],
                mode: .topLevelChildren),
            CodexWorkspaceDomainScanner(
                domain: .codexWorkspaces,
                kind: .codexWorkspace,
                roots: roots[.codexWorkspaces] ?? [],
                mode: .topLevelChildren),
            SimulatorDeviceDomainScanner(roots: roots[.coreSimulatorDevices] ?? []),
            XCTestDevicesDomainScanner(roots: roots[.xcTestDevices] ?? []),
            DerivedDataDomainScanner(roots: roots[.derivedData] ?? []),
            XcodeProductsDomainScanner(roots: roots[.xcodeProducts] ?? []),
            XCResultDomainScanner(roots: roots[.xcResults] ?? []),
            KnownDirectoryDomainScanner(
                domain: .deviceSupport,
                kind: .deviceSupport,
                roots: roots[.deviceSupport] ?? [],
                mode: .topLevelChildren),
            SimulatorRuntimeComponentScanner(
                domain: .simulatorRuntimes,
                kind: .simulatorRuntime,
                roots: roots[.simulatorRuntimes] ?? [],
                packageExtension: "simruntime"),
            SimulatorRuntimeComponentScanner(
                domain: .simulatorImages,
                kind: .simulatorImage,
                roots: roots[.simulatorImages] ?? []),
            KnownDirectoryDomainScanner(
                domain: .coreSimulatorCaches,
                kind: .coreSimulatorCache,
                roots: roots[.coreSimulatorCaches] ?? [],
                mode: .topLevelChildren),
            KnownDirectoryDomainScanner(
                domain: .archives,
                kind: .archive,
                roots: roots[.archives] ?? [],
                mode: .matchingPackages(extensionName: "xcarchive")),
            KnownDirectoryDomainScanner(
                domain: .swiftPackageCaches,
                kind: .swiftPackageCache,
                roots: roots[.swiftPackageCaches] ?? [],
                mode: .wholeRoots),
        ]
    }

    private func classify(
        items: [StorageItem],
        configuration: StorageScanConfiguration,
        now: Date) async -> [StorageItem]
    {
        var classifiedItems: [StorageItem] = []

        for item in items {
            var item = item
            var decision = safetyPolicy.classify(item: item, configuration: configuration, now: now)
            if needsOpenFileCheck(item: item, decision: decision) {
                switch await openFileChecker.checkOpenFiles(under: URL(fileURLWithPath: item.path)) {
                case .clear:
                    item.metadata["openFileCheck"] = "clear"
                case .openFilesFound:
                    item.isActive = true
                    item.metadata["openFileCheck"] = "open"
                    decision = safetyPolicy.classify(item: item, configuration: configuration, now: now)
                case let .unavailable(reason):
                    item.metadata["openFileCheck"] = "unavailable"
                    item.metadata["openFileCheckReason"] = reason
                    decision = SafetyDecision(
                        classification: .keep,
                        reason: "Open-file check with lsof could not be completed, so this item is excluded from cleanup.")
                }
            }

            item.safety = decision.classification
            item.explanation = "\(item.explanation) \(decision.reason)"
            if item.cleanupImpact.isEmpty {
                item.cleanupImpact = item.suggestedAction.explanation
            }
            classifiedItems.append(item)
        }

        return classifiedItems
    }

    private func needsOpenFileCheck(item: StorageItem, decision: SafetyDecision) -> Bool {
        guard decision.classification == .safeToTrash || decision.classification == .probablySafe else {
            return false
        }

        switch item.domain {
        case .coreSimulatorDevices, .simulatorRuntimes, .simulatorImages:
            return false
        case .codexHome, .codexWorkspaces, .xcTestDevices, .derivedData, .xcResults, .xcodeProducts,
             .deviceSupport, .coreSimulatorCaches, .archives, .swiftPackageCaches:
            return true
        }
    }

    private func deduplicated(_ items: [StorageItem]) -> [StorageItem] {
        var seen: Set<String> = []
        var result: [StorageItem] = []
        for item in items.sorted(by: { $0.bytes > $1.bytes }) {
            let path = URL(fileURLWithPath: item.path).standardizedFileURL.path
            guard seen.insert(path).inserted else {
                continue
            }
            result.append(item)
        }
        return result
    }

    private func unique(_ paths: [String]) -> [String] {
        Array(Set(paths.map { URL(fileURLWithPath: $0).standardizedFileURL.path })).sorted()
    }
}
