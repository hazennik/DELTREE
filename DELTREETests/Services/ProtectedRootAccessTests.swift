import Foundation
import Testing
@testable import DELTREE

struct ProtectedRootAccessTests {
    @Test func documentsRootIsCheckedOnceAndExcludedAfterDenial() async {
        let homeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DELTREE-protected-root-\(UUID().uuidString)", isDirectory: true)
        let rootCatalog = StorageRootCatalog(homeDirectory: homeDirectory)
        let accessChecker = RecordingProtectedRootAccessChecker(result: .unreadable)
        let scanner = DefaultStorageScanner(
            rootCatalog: rootCatalog,
            fileSizeScanner: EmptyFileSizeScanner(),
            simctlClient: EmptySimctlClient(),
            codexSessionScanner: EmptyCodexSessionScanner(),
            processSampler: EmptyProcessSampler(),
            openFileChecker: ClearOpenFileChecker(),
            attributionTracker: EmptyAttributionTracker(),
            protectedRootAccessChecker: accessChecker)

        let snapshot = await scanner.scan(configuration: .standard)

        #expect(accessChecker.checkCount == 1)
        #expect(snapshot.unreadablePaths.contains(rootCatalog.documentsCodexRoot.path))
        #expect(snapshot.items.contains { $0.path.hasPrefix(rootCatalog.documentsCodexRoot.path) } == false)
    }

    @Test func disabledDocumentsRootIsNotCheckedOrWatched() async {
        let homeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DELTREE-disabled-protected-root-\(UUID().uuidString)", isDirectory: true)
        let rootCatalog = StorageRootCatalog(homeDirectory: homeDirectory)
        let accessChecker = RecordingProtectedRootAccessChecker(result: .unreadable)
        let scanner = DefaultStorageScanner(
            rootCatalog: rootCatalog,
            fileSizeScanner: EmptyFileSizeScanner(),
            simctlClient: EmptySimctlClient(),
            codexSessionScanner: EmptyCodexSessionScanner(),
            processSampler: EmptyProcessSampler(),
            openFileChecker: ClearOpenFileChecker(),
            attributionTracker: EmptyAttributionTracker(),
            protectedRootAccessChecker: accessChecker)
        var configuration = StorageScanConfiguration.standard
        configuration.scanDocumentsCodex = false

        let snapshot = await scanner.scan(configuration: configuration)

        #expect(accessChecker.checkCount == 0)
        #expect(snapshot.unreadablePaths.contains(rootCatalog.documentsCodexRoot.path) == false)
        #expect(rootCatalog.watchRoots(configuration: configuration).contains(rootCatalog.documentsCodexRoot.path) == false)
    }
}

private final class RecordingProtectedRootAccessChecker: ProtectedRootAccessChecking, @unchecked Sendable {
    private let lock = NSLock()
    private let result: ProtectedRootAccessResult
    private var storedCheckCount = 0

    init(result: ProtectedRootAccessResult) {
        self.result = result
    }

    var checkCount: Int {
        lock.withLock { storedCheckCount }
    }

    func checkAccess(to root: URL) -> ProtectedRootAccessResult {
        lock.withLock {
            storedCheckCount += 1
        }
        return result
    }
}

private struct EmptyFileSizeScanner: FileSizeScanning {
    func size(of url: URL) -> FileSizeResult {
        FileSizeResult(bytes: 0, unreadablePaths: [])
    }
}

private struct EmptySimctlClient: SimctlClient {
    func devices() async -> [SimctlDevice] { [] }
}

private struct EmptyCodexSessionScanner: CodexSessionScanning {
    func sessions(now: Date) async -> [CodexSessionRecord] { [] }
}

private struct EmptyProcessSampler: ProcessSampling {
    func sample() async -> ProcessSnapshot {
        ProcessSnapshot(sampledAt: Date(), processes: [])
    }
}

private struct ClearOpenFileChecker: OpenFileChecking {
    func checkOpenFiles(under url: URL) async -> OpenFileCheckResult { .clear }
}

private struct EmptyAttributionTracker: AttributionTracking {
    func recordFilesystemEvents(paths: [String], processes: ProcessSnapshot, at date: Date) async {}

    func attribution(
        forPath path: String,
        domain: StorageDomain,
        kind: StorageKind,
        metadata: [String: String],
        processes: ProcessSnapshot,
        now: Date) async -> AttributionResult
    {
        AttributionResult(owner: .unknown, confidence: 0, reason: "Fixture")
    }
}
