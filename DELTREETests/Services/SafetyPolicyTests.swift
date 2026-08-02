import Foundation
import Testing
@testable import DELTREE

struct SafetyPolicyTests {
    private let policy = DefaultSafetyPolicy()

    @Test func activeSimulatorIsKept() {
        var item = Self.item(domain: .coreSimulatorDevices, kind: .simulatorDevice)
        item.isActive = true

        let decision = policy.classify(item: item, configuration: .standard, now: Date())

        #expect(decision.classification == .keep)
    }

    @Test func archivesAndRuntimesAreNotOneClickSafe() {
        let archive = Self.item(domain: .archives, kind: .archive)
        let runtime = Self.item(domain: .simulatorRuntimes, kind: .simulatorRuntime)

        #expect(policy.classify(item: archive, configuration: .standard, now: Date()).classification == .reviewRecommended)
        #expect(policy.classify(item: runtime, configuration: .standard, now: Date()).classification == .keep)
    }

    @Test func staleCodexAttributedXCTestDeviceIsSafe() {
        var item = Self.item(domain: .xcTestDevices, kind: .xcTestDevice)
        item.attribution = .xcodeViaCodex
        item.lastUsedAt = Date().addingTimeInterval(-30 * 86_400)

        let decision = policy.classify(item: item, configuration: .standard, now: Date())

        #expect(decision.classification == .safeToTrash)
    }

    @Test func keepLastTestRunsProtectsResultBundles() {
        var item = Self.item(domain: .xcResults, kind: .xcResult)
        item.attribution = .xcodeViaCodex
        item.metadata["protectedByKeepLastTestRuns"] = "true"

        let decision = policy.classify(item: item, configuration: .standard, now: Date())

        #expect(decision.classification == .reviewRecommended)
        #expect(decision.reason.contains("keep-last-test-runs"))
    }

    @Test func pinnedAndIgnoredItemsAreKept() {
        var pinned = Self.item(domain: .derivedData, kind: .derivedData)
        pinned.isPinned = true
        var ignored = Self.item(domain: .xcResults, kind: .xcResult)
        ignored.isIgnored = true

        #expect(policy.classify(item: pinned, configuration: .standard, now: Date()).classification == .keep)
        #expect(policy.classify(item: ignored, configuration: .standard, now: Date()).classification == .keep)
    }

    private static func item(domain: StorageDomain, kind: StorageKind) -> StorageItem {
        StorageItem(
            id: UUID().uuidString,
            domain: domain,
            kind: kind,
            path: "/tmp/\(UUID().uuidString)",
            displayName: "Fixture",
            bytes: 1_024,
            createdAt: Date().addingTimeInterval(-30 * 86_400),
            modifiedAt: Date().addingTimeInterval(-30 * 86_400),
            lastUsedAt: Date().addingTimeInterval(-30 * 86_400),
            attribution: .xcode,
            attributionConfidence: 0.5,
            safety: .unknown,
            isActive: false,
            explanation: "Fixture",
            metadata: [:])
    }
}

struct StorageScannerOpenFileCheckTests {
    @Test func clearOpenFileCheckAllowsCodexCacheSafe() async throws {
        let result = try await scanCodexCache(openFileCheckResult: .clear)
        let checkedPaths = await result.openFileChecker.checkedPaths()

        #expect(result.item.safety == .safeToTrash)
        #expect(result.item.isActive == false)
        #expect(result.item.metadata["openFileCheck"] == "clear")
        #expect(checkedPaths == [result.cache.standardizedFileURL.path])
    }

    @Test func openFileCheckBlocksCodexCacheSafe() async throws {
        let result = try await scanCodexCache(openFileCheckResult: .openFilesFound)

        #expect(result.item.safety == .keep)
        #expect(result.item.isActive)
        #expect(result.item.metadata["openFileCheck"] == "open")
    }

    @Test func unavailableOpenFileCheckBlocksCodexCacheSafe() async throws {
        let result = try await scanCodexCache(openFileCheckResult: .unavailable("lsof failed"))

        #expect(result.item.safety == .keep)
        #expect(result.item.isActive == false)
        #expect(result.item.metadata["openFileCheck"] == "unavailable")
        #expect(result.item.metadata["openFileCheckReason"] == "lsof failed")
    }

    @Test func simulatorDeviceSafetyDoesNotUseLsofGate() async throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("DELTREE-simulator-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }

        let deviceURL = root.appendingPathComponent("Library/Developer/CoreSimulator/Devices/SIM-123", isDirectory: true)
        try fileManager.createDirectory(at: deviceURL, withIntermediateDirectories: true)
        try Data("fixture".utf8).write(to: deviceURL.appendingPathComponent("data"))

        let checker = RecordingOpenFileChecker(result: .unavailable("lsof should not run"))
        let scanner = DefaultStorageScanner(
            rootCatalog: StorageRootCatalog(homeDirectory: root),
            fileManager: fileManager,
            fileSizeScanner: LiveFileSizeScanner(fileManager: fileManager),
            simctlClient: StaticSimctlClient(devices: [
                SimctlDevice(
                    udid: "SIM-123",
                    name: "Unavailable iPhone",
                    state: "Shutdown",
                    isAvailable: false,
                    availabilityError: "runtime unavailable",
                    runtimeIdentifier: "com.apple.CoreSimulator.SimRuntime.iOS-18-0",
                    dataPath: deviceURL.path,
                    logPath: nil,
                    lastBootedAt: Date().addingTimeInterval(-30 * 86_400)),
            ]),
            codexSessionScanner: EmptyCodexSessionScanner(),
            processSampler: EmptyProcessSampler(),
            openFileChecker: checker,
            attributionTracker: LiveAttributionTracker())

        let snapshot = await scanner.scan(configuration: .standard, now: Date())
        let item = try #require(snapshot.items.first { $0.path == deviceURL.standardizedFileURL.path })
        let checkedPaths = await checker.checkedPaths()

        #expect(item.safety == .safeToTrash)
        #expect(checkedPaths.isEmpty)
    }

    private func scanCodexCache(openFileCheckResult: OpenFileCheckResult) async throws -> ScanResult {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("DELTREE-codex-cache-\(UUID().uuidString)", isDirectory: true)
        let cache = root.appendingPathComponent(".codex/cache", isDirectory: true)
        try fileManager.createDirectory(at: cache, withIntermediateDirectories: true)
        try Data("fixture".utf8).write(to: cache.appendingPathComponent("payload"))

        let checker = RecordingOpenFileChecker(result: openFileCheckResult)
        let scanner = DefaultStorageScanner(
            rootCatalog: StorageRootCatalog(homeDirectory: root),
            fileManager: fileManager,
            fileSizeScanner: LiveFileSizeScanner(fileManager: fileManager),
            simctlClient: StaticSimctlClient(devices: []),
            codexSessionScanner: EmptyCodexSessionScanner(),
            processSampler: EmptyProcessSampler(),
            openFileChecker: checker,
            attributionTracker: LiveAttributionTracker())

        let snapshot = await scanner.scan(configuration: .standard, now: Date())
        let item = try #require(snapshot.items.first { $0.path == cache.standardizedFileURL.path })
        try? fileManager.removeItem(at: root)

        return ScanResult(item: item, cache: cache, openFileChecker: checker)
    }
}

private struct ScanResult {
    var item: StorageItem
    var cache: URL
    var openFileChecker: RecordingOpenFileChecker
}

private actor RecordingOpenFileChecker: OpenFileChecking {
    private let result: OpenFileCheckResult
    private var paths: [String] = []

    init(result: OpenFileCheckResult) {
        self.result = result
    }

    func checkOpenFiles(under url: URL) async -> OpenFileCheckResult {
        paths.append(url.standardizedFileURL.path)
        return result
    }

    func checkedPaths() -> [String] {
        paths
    }
}

private struct StaticSimctlClient: SimctlClient {
    var storedDevices: [SimctlDevice]

    init(devices: [SimctlDevice]) {
        storedDevices = devices
    }

    func devices() async -> [SimctlDevice] {
        storedDevices
    }
}

private struct EmptyCodexSessionScanner: CodexSessionScanning {
    func sessions(now: Date) async -> [CodexSessionRecord] {
        []
    }
}

private struct EmptyProcessSampler: ProcessSampling {
    func sample() async -> ProcessSnapshot {
        ProcessSnapshot(sampledAt: Date(), processes: [])
    }
}
