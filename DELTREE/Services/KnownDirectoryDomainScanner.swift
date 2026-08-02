import Foundation

struct KnownDirectoryDomainScanner: DomainScanning {
    var domain: StorageDomain
    private let kind: StorageKind
    private let roots: [URL]
    private let mode: DirectoryScanMode

    init(domain: StorageDomain, kind: StorageKind, roots: [URL], mode: DirectoryScanMode) {
        self.domain = domain
        self.kind = kind
        self.roots = roots
        self.mode = mode
    }

    func scan(context: DomainScanContext) async -> DomainScanResult {
        var result = DomainScanResult.empty

        for root in roots {
            if Task.isCancelled {
                break
            }

            let rootPath = root.standardizedFileURL.path
            guard context.configuration.isExcluded(rootPath) == false else {
                continue
            }

            var isDirectory: ObjCBool = false
            guard context.fileManager.fileExists(atPath: rootPath, isDirectory: &isDirectory) else {
                result.missingPaths.append(rootPath)
                continue
            }

            let candidates = candidateURLs(root: root, isDirectory: isDirectory.boolValue, context: context)
            for candidate in candidates where context.configuration.isExcluded(candidate.path) == false {
                let size = context.fileSizeScanner.size(of: candidate)
                result.unreadablePaths.append(contentsOf: size.unreadablePaths)
                guard size.bytes > 0 else {
                    continue
                }

                var metadata = ["root": rootPath]
                metadata["suggestedAction"] = suggestedAction.rawValue
                metadata.merge(CodexSessionMatcher.metadata(for: candidate.path, sessions: context.codexSessions)) { current, _ in current }

                let item = await StorageItemFactory.makeItem(
                    url: candidate,
                    domain: domain,
                    kind: kind,
                    size: size,
                    metadata: metadata,
                    isActive: false,
                    explicitLastUsedAt: nil,
                    context: context)
                result.items.append(item)
            }
        }

        return result
    }

    private func candidateURLs(root: URL, isDirectory: Bool, context: DomainScanContext) -> [URL] {
        switch mode {
        case .wholeRoots:
            return [root]
        case .topLevelChildren:
            guard isDirectory else {
                return [root]
            }
            return (try? context.fileManager.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey],
                options: [.skipsHiddenFiles])) ?? []
        case let .matchingPackages(extensionName):
            guard isDirectory else {
                return root.pathExtension == extensionName ? [root] : []
            }
            return packageURLs(root: root, extensionName: extensionName, context: context)
        }
    }

    private func packageURLs(root: URL, extensionName: String, context: DomainScanContext) -> [URL] {
        guard let enumerator = context.fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true })
        else {
            return []
        }

        var matches: [URL] = []
        for case let url as URL in enumerator {
            if Task.isCancelled {
                enumerator.skipDescendants()
                break
            }

            if url.pathExtension == extensionName {
                matches.append(url)
                enumerator.skipDescendants()
            }
        }
        return matches
    }

    private var suggestedAction: StorageAction {
        switch domain {
        case .xcResults:
            .removeXCResult
        case .derivedData:
            .cleanDerivedData
        case .codexWorkspaces:
            .removeCodexWorkspace
        case .codexHome, .xcTestDevices, .xcodeProducts, .coreSimulatorCaches:
            .moveToTrash
        case .coreSimulatorDevices, .deviceSupport, .simulatorRuntimes, .simulatorImages, .archives, .swiftPackageCaches:
            .none
        }
    }
}
