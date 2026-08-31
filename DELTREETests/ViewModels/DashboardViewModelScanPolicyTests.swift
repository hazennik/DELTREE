import Foundation
import Testing
@testable import DELTREE

@MainActor
struct DashboardViewModelScanPolicyTests {
    @Test func manualScanRunsImmediatelyEvenInLowPowerMode() async throws {
        let harness = try await DashboardViewModelHarness(
            scanIntervalMinutes: 1,
            powerState: PowerState(isOnBatteryPower: true, isLowPowerModeEnabled: true))

        harness.viewModel.scan(force: true)
        try await harness.waitForScanCompletion(count: 1)

        #expect(harness.scheduler.scheduledDelays.isEmpty)
    }

    @Test func normalAutomaticScanUsesUserIntervalWhenItIsLargerThanPolicyMinimum() async throws {
        let harness = try await DashboardViewModelHarness(
            scanIntervalMinutes: 5,
            powerState: PowerState(isOnBatteryPower: false, isLowPowerModeEnabled: false))

        harness.viewModel.scan(force: true)
        try await harness.waitForScanCompletion(count: 1)
        harness.viewModel.scan(force: false)

        #expect(harness.scheduler.scheduledDelays == [5 * 60])
        #expect(await harness.scanner.scanCount() == 1)
    }

    @Test func batteryAutomaticScanUsesTenMinuteMinimumWhenUserIntervalIsShorter() async throws {
        let harness = try await DashboardViewModelHarness(
            scanIntervalMinutes: 1,
            powerState: PowerState(isOnBatteryPower: true, isLowPowerModeEnabled: false))

        harness.viewModel.scan(force: true)
        try await harness.waitForScanCompletion(count: 1)
        harness.viewModel.scan(force: false)

        #expect(harness.scheduler.scheduledDelays == [10 * 60])
        #expect(await harness.scanner.scanCount() == 1)
    }

    @Test func lowPowerAutomaticScanUsesThirtyMinuteMinimum() async throws {
        let harness = try await DashboardViewModelHarness(
            scanIntervalMinutes: 1,
            powerState: PowerState(isOnBatteryPower: true, isLowPowerModeEnabled: true))

        harness.viewModel.scan(force: true)
        try await harness.waitForScanCompletion(count: 1)
        harness.viewModel.scan(force: false)

        #expect(harness.scheduler.scheduledDelays == [30 * 60])
        #expect(await harness.scanner.scanCount() == 1)
    }

    @Test func filesystemTriggeredScanUsesBackgroundPolicyDelay() async throws {
        let harness = try await DashboardViewModelHarness(
            scanIntervalMinutes: 1,
            powerState: PowerState(isOnBatteryPower: false, isLowPowerModeEnabled: true))

        harness.viewModel.start()
        try await harness.waitForScanCompletion(count: 1)
        harness.watcher.emit(paths: ["/tmp/changed"])
        try await harness.waitForScheduledDelayCount(1)

        #expect(harness.scheduler.scheduledDelays == [30 * 60])
        harness.viewModel.stop()
    }

    @Test func startHydratesPersistedSnapshotBeforeInitialScanCompletes() async throws {
        let cachedSnapshot = Self.snapshot(index: 42)
        let harness = try await DashboardViewModelHarness(
            scanIntervalMinutes: 1,
            powerState: PowerState(isOnBatteryPower: false, isLowPowerModeEnabled: false),
            persistedSnapshots: [cachedSnapshot])
        await harness.scanner.setBlocksScans(true)

        harness.viewModel.start()
        try await harness.waitForScanStart(count: 1)

        #expect(harness.viewModel.snapshot == cachedSnapshot)
        #expect(harness.viewModel.previousSnapshot == cachedSnapshot)
        #expect(harness.viewModel.isScanning)

        await harness.scanner.resumeBlockedScan()
        try await harness.waitForScanCompletion(count: 1)
        harness.viewModel.stop()
    }

    @Test func pendingAutomaticScanAfterCurrentUsesBackgroundPolicyDelay() async throws {
        let harness = try await DashboardViewModelHarness(
            scanIntervalMinutes: 1,
            powerState: PowerState(isOnBatteryPower: true, isLowPowerModeEnabled: false))
        await harness.scanner.setBlocksScans(true)

        harness.viewModel.scan(force: true)
        try await harness.waitForScanStart(count: 1)
        harness.viewModel.scan(force: false)
        await harness.scanner.resumeBlockedScan()
        try await harness.waitForScheduledDelayCount(1)

        #expect(harness.scheduler.scheduledDelays == [10 * 60])
        #expect(await harness.scanner.scanCount() == 1)
    }

    @Test func pendingManualScanAfterCurrentRunsImmediately() async throws {
        let harness = try await DashboardViewModelHarness(
            scanIntervalMinutes: 1,
            powerState: PowerState(isOnBatteryPower: true, isLowPowerModeEnabled: true))
        await harness.scanner.setBlocksScans(true)

        harness.viewModel.scan(force: true)
        try await harness.waitForScanStart(count: 1)
        harness.viewModel.scan(force: true)
        await harness.scanner.resumeBlockedScan()
        try await harness.waitForScanCompletion(count: 2)

        #expect(harness.scheduler.scheduledDelays.isEmpty)
    }

    @Test func forcedScanRecoversWhenExistingScanIsStale() async throws {
        let harness = try await DashboardViewModelHarness(
            scanIntervalMinutes: 1,
            powerState: PowerState(isOnBatteryPower: false, isLowPowerModeEnabled: false))
        await harness.scanner.setBlocksScans(true)

        harness.viewModel.scan(force: true)
        try await harness.waitForScanStart(count: 1)

        harness.clock.advance(by: 121)
        await harness.scanner.setBlocksScans(false)
        harness.viewModel.scan(force: true)
        try await harness.waitForScanCompletion(count: 2)

        #expect(await harness.scanner.scanCount() == 2)
        #expect(harness.viewModel.isScanning == false)
    }

    @Test func deniedDocumentsAccessDisablesAutomaticRetries() async throws {
        let harness = try await DashboardViewModelHarness(
            scanIntervalMinutes: 1,
            powerState: PowerState(isOnBatteryPower: false, isLowPowerModeEnabled: false))
        await harness.scanner.setSnapshot(StorageSnapshot(
            capturedAt: harness.clock.now,
            items: [],
            missingPaths: [],
            unreadablePaths: [harness.documentsCodexPath]))

        harness.viewModel.start()
        try await harness.waitForScanCompletion(count: 1)

        #expect(harness.viewModel.settings.scanDocumentsCodex == false)
        #expect(harness.viewModel.settings.scanConfiguration.scanDocumentsCodex == false)
        #expect(harness.watcher.startedPaths.contains(harness.documentsCodexPath) == false)
        harness.viewModel.stop()
    }

    @Test func verifiedDocumentsAccessEnablesFilesystemWatching() async throws {
        let harness = try await DashboardViewModelHarness(
            scanIntervalMinutes: 1,
            powerState: PowerState(isOnBatteryPower: false, isLowPowerModeEnabled: false))

        harness.viewModel.start()
        try await harness.waitForScanCompletion(count: 1)

        #expect(harness.viewModel.settings.scanDocumentsCodex)
        #expect(harness.watcher.startedPaths.contains(harness.documentsCodexPath))
        harness.viewModel.stop()
    }

    @Test func cleanupExecutionIgnoresDuplicateSubmission() async throws {
        let cleanupExecutor = CountingCleanupExecutor()
        let harness = try await DashboardViewModelHarness(
            scanIntervalMinutes: 1,
            powerState: PowerState(isOnBatteryPower: false, isLowPowerModeEnabled: false),
            cleanupExecutor: cleanupExecutor)
        let item = Self.item(index: 300)
        let plan = CleanupPlan(
            actions: [CleanupPlanAction(item: item, action: .moveToTrash, reason: "Fixture")],
            blockedItems: [])

        harness.viewModel.pendingCleanupPlan = plan
        harness.viewModel.performCleanup(plan)
        harness.viewModel.performCleanup(plan)
        try await harness.waitForCleanupExecutionCount(1, executor: cleanupExecutor)

        #expect(await cleanupExecutor.executionCount == 1)
        #expect(harness.viewModel.pendingCleanupPlan == nil)
    }

    @Test func memoryPressureTrimDropsOnlyRebuildableState() async throws {
        let harness = try await DashboardViewModelHarness(
            scanIntervalMinutes: 1,
            powerState: PowerState(isOnBatteryPower: false, isLowPowerModeEnabled: false))
        let currentSnapshot = Self.snapshot(index: 100)
        let previousSnapshot = Self.snapshot(index: 99)
        let pendingPlan = CleanupPlan(actions: [], blockedItems: [Self.item(index: 200)])

        harness.viewModel.snapshot = currentSnapshot
        harness.viewModel.previousSnapshot = previousSnapshot
        harness.viewModel.pendingCleanupPlan = pendingPlan
        harness.viewModel.scanHistory = (0..<6).map { ScanHistoryRecord(snapshot: Self.snapshot(index: $0)) }
        harness.viewModel.cleanupHistory = (0..<5).map {
            CleanupHistoryRecord(
                performedAt: Date(timeIntervalSince1970: TimeInterval($0)),
                totalBytes: Int64($0),
                itemCount: 1,
                status: "completed",
                paths: ["/tmp/item-\($0)"])
        }
        harness.viewModel.deltaHistory = (0..<4).map {
            StorageDeltaRecord(delta: StorageDelta(
                fromDate: nil,
                toDate: Date(timeIntervalSince1970: TimeInterval($0)),
                addedBytes: Int64($0),
                changedBytes: 0,
                removedBytes: 0,
                newItems: [],
                changedItems: [],
                removedPaths: []))
        }

        let summary = harness.viewModel.trimTransientStateForMemoryPressure(level: .warning)

        #expect(summary == MemoryPressureTrimSummary(
            level: .warning,
            releasedPreviousSnapshot: true,
            scanHistoryTrimmedCount: 3,
            cleanupHistoryTrimmedCount: 2,
            deltaHistoryTrimmedCount: 1,
            diagnosticsTrimmedCount: 0))
        #expect(harness.viewModel.previousSnapshot == nil)
        #expect(harness.viewModel.snapshot == currentSnapshot)
        #expect(harness.viewModel.pendingCleanupPlan == pendingPlan)
        #expect(harness.viewModel.scanHistory.count == 3)
        #expect(harness.viewModel.cleanupHistory.count == 3)
        #expect(harness.viewModel.deltaHistory.count == 3)
    }

    private static func snapshot(index: Int) -> StorageSnapshot {
        StorageSnapshot(
            capturedAt: Date(timeIntervalSince1970: TimeInterval(index)),
            items: [item(index: index)],
            missingPaths: [],
            unreadablePaths: [])
    }

    private static func item(index: Int) -> StorageItem {
        StorageItem(
            id: "item-\(index)",
            domain: .derivedData,
            kind: .derivedData,
            path: "/tmp/item-\(index)",
            displayName: "Item \(index)",
            bytes: Int64(index),
            createdAt: Date(timeIntervalSince1970: TimeInterval(index)),
            modifiedAt: Date(timeIntervalSince1970: TimeInterval(index)),
            lastUsedAt: Date(timeIntervalSince1970: TimeInterval(index)),
            attribution: .xcode,
            attributionConfidence: 0.9,
            safety: .reviewRecommended,
            isActive: false,
            explanation: "Fixture",
            metadata: [:])
    }
}

@MainActor
private final class DashboardViewModelHarness {
    let viewModel: DashboardViewModel
    let scanner: RecordingStorageScanner
    let scheduler: RecordingScanDelayScheduler
    let watcher: RecordingStorageWatcher
    let clock: DashboardViewModelTestClock
    let persistence: InMemorySnapshotPersistence
    let documentsCodexPath: String

    private let suiteName = "DELTREE.DashboardViewModelScanPolicyTests.\(UUID().uuidString)"

    init(
        scanIntervalMinutes: Double,
        powerState: PowerState,
        persistedSnapshots: [StorageSnapshot] = [],
        cleanupExecutor: any CleanupExecuting = NoopCleanupExecutor()) async throws
    {
        let scanner = RecordingStorageScanner()
        let scheduler = RecordingScanDelayScheduler()
        let watcher = RecordingStorageWatcher()
        let clock = DashboardViewModelTestClock()
        let persistence = InMemorySnapshotPersistence(snapshots: persistedSnapshots)
        self.scanner = scanner
        self.scheduler = scheduler
        self.watcher = watcher
        self.clock = clock
        self.persistence = persistence

        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        let settings = AppSettingsStore(defaults: defaults)
        settings.scanIntervalMinutes = scanIntervalMinutes
        settings.notificationsEnabled = false
        settings.autoScanAfterActivity = true

        let homeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("DELTREE-scan-policy-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: homeDirectory, withIntermediateDirectories: true)
        documentsCodexPath = StorageRootCatalog(homeDirectory: homeDirectory).documentsCodexRoot.path

        viewModel = DashboardViewModel(
            scanner: scanner,
            cleanupPlanner: NoopCleanupPlanner(),
            cleanupExecutor: cleanupExecutor,
            persistence: persistence,
            settings: settings,
            watcher: watcher,
            rootCatalog: StorageRootCatalog(homeDirectory: homeDirectory),
            processSampler: EmptyProcessSampler(),
            attributionTracker: NoopAttributionTracker(),
            diskSpaceProvider: StaticDiskSpaceProvider(),
            notificationService: NoopNotificationService(),
            mainThreadHangWatchdog: .disabled(),
            powerStateProvider: StaticPowerStateProvider(powerState: powerState),
            backgroundScanPolicy: .production,
            now: { clock.now },
            scheduleScanDelay: { seconds, operation in
                scheduler.schedule(seconds: seconds, operation: operation)
            })
    }

    deinit {
        UserDefaults(suiteName: suiteName)?.removePersistentDomain(forName: suiteName)
    }

    func waitForScanStart(count expectedCount: Int) async throws {
        try await waitUntil {
            await self.scanner.scanCount() >= expectedCount
        }
    }

    func waitForScanCompletion(count expectedCount: Int) async throws {
        try await waitForScanStart(count: expectedCount)
        try await waitUntil {
            await self.scanner.scanCount() >= expectedCount && self.viewModel.isScanning == false
        }
    }

    func waitForScheduledDelayCount(_ expectedCount: Int) async throws {
        try await waitUntil {
            self.scheduler.scheduledDelays.count >= expectedCount
        }
    }

    func waitForCleanupExecutionCount(_ expectedCount: Int, executor: CountingCleanupExecutor) async throws {
        try await waitUntil {
            await executor.executionCount >= expectedCount
        }
    }

    private func waitUntil(_ predicate: @escaping @MainActor () async -> Bool) async throws {
        for _ in 0..<300 {
            if await predicate() {
                return
            }
            try await Task.sleep(for: .milliseconds(10))
        }
        #expect(await predicate())
    }
}

@MainActor
private final class RecordingScanDelayScheduler {
    private(set) var scheduledDelays: [TimeInterval] = []
    private(set) var cancellationCount = 0
    private var operations: [@MainActor () -> Void] = []

    func schedule(seconds: TimeInterval, operation: @escaping @MainActor () -> Void) -> @MainActor () -> Void {
        scheduledDelays.append(seconds)
        operations.append(operation)
        return {
            self.cancellationCount += 1
        }
    }

    func runNext() {
        guard operations.isEmpty == false else {
            return
        }
        operations.removeFirst()()
    }
}

private struct StaticPowerStateProvider: PowerStateProviding {
    var powerState: PowerState

    var currentPowerState: PowerState {
        powerState
    }
}

private final class RecordingStorageScanner: StorageScanning, @unchecked Sendable {
    private let state = RecordingStorageScannerState()

    @concurrent func scan(configuration: StorageScanConfiguration, now: Date) async -> StorageSnapshot {
        await state.scan(now: now)
    }

    func scanCount() async -> Int {
        await state.scanCount
    }

    func setBlocksScans(_ blocksScans: Bool) async {
        await state.setBlocksScans(blocksScans)
    }

    func setSnapshot(_ snapshot: StorageSnapshot) async {
        await state.setSnapshot(snapshot)
    }

    func resumeBlockedScan() async {
        await state.resumeBlockedScan()
    }
}

private actor RecordingStorageScannerState {
    var scanCount = 0
    private var blocksScans = false
    private var snapshot: StorageSnapshot?

    func scan(now: Date) async -> StorageSnapshot {
        scanCount += 1
        while blocksScans {
            if Task.isCancelled {
                break
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return snapshot ?? StorageSnapshot(capturedAt: now, items: [], missingPaths: [], unreadablePaths: [])
    }

    func setBlocksScans(_ blocksScans: Bool) {
        self.blocksScans = blocksScans
    }

    func setSnapshot(_ snapshot: StorageSnapshot) {
        self.snapshot = snapshot
    }

    func resumeBlockedScan() {
        blocksScans = false
    }
}

@MainActor
private final class InMemorySnapshotPersistence: SnapshotPersisting {
    private var snapshots: [StorageSnapshot] = []
    private var overrides: [String: ManualStorageOverride] = [:]

    init(snapshots: [StorageSnapshot] = []) {
        self.snapshots = snapshots
    }

    func saveSnapshot(_ snapshot: StorageSnapshot) throws {
        snapshots.append(snapshot)
    }

    func mostRecentSnapshot() -> StorageSnapshot? {
        snapshots.last
    }

    func saveDelta(_ delta: StorageDelta) throws {}

    func saveCleanup(
        performedAt: Date,
        totalBytes: Int64,
        itemCount: Int,
        status: String,
        paths: [String],
        skippedPaths: [String],
        errors: [String: String],
        initiator: String) throws
    {}

    func saveAttributionEvent(owner: OwnerAttribution, confidence: Double, paths: [String], observedAt: Date) throws {}

    func saveManualOverride(_ override: ManualStorageOverride) throws {
        overrides[override.path] = override
    }

    func clearManualOverride(path: String) throws {
        overrides.removeValue(forKey: path)
    }

    func manualOverrides() -> [String: ManualStorageOverride] {
        overrides
    }

    func recentCleanupRecords(limit: Int) -> [CleanupHistoryRecord] { [] }
    func recentScanRecords(limit: Int) -> [ScanHistoryRecord] { [] }
    func recentDeltaRecords(limit: Int) -> [StorageDeltaRecord] { [] }
}

private final class RecordingStorageWatcher: StorageWatching, @unchecked Sendable {
    var onChange: (@Sendable ([String]) -> Void)?
    private(set) var startedPaths: [String] = []

    func start(paths: [String]) {
        startedPaths = paths
    }

    func stop() {}

    func emit(paths: [String]) {
        onChange?(paths)
    }
}

private struct NoopCleanupPlanner: CleanupPlanning {
    func planSafeCleanup(from snapshot: StorageSnapshot) -> CleanupPlan {
        CleanupPlan(actions: [], blockedItems: [])
    }

    func planCleanup(for item: StorageItem, action: StorageAction, in snapshot: StorageSnapshot) -> CleanupPlan {
        CleanupPlan(actions: [], blockedItems: [])
    }
}

private struct NoopCleanupExecutor: CleanupExecuting {
    func execute(_ plan: CleanupPlan) async -> CleanupExecutionResult {
        CleanupExecutionResult(performedAt: Date(), completedActions: [], failedActions: [:], skippedItems: [])
    }
}

private actor CountingCleanupExecutor: CleanupExecuting {
    private(set) var executionCount = 0

    func execute(_ plan: CleanupPlan) async -> CleanupExecutionResult {
        executionCount += 1
        return CleanupExecutionResult(
            performedAt: Date(),
            completedActions: [],
            failedActions: [:],
            skippedItems: [])
    }
}

private struct NoopAttributionTracker: AttributionTracking {
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

private struct EmptyProcessSampler: ProcessSampling {
    func sample() async -> ProcessSnapshot {
        ProcessSnapshot(sampledAt: Date(), processes: [])
    }
}

private struct StaticDiskSpaceProvider: DiskSpaceProviding {
    func availableBytes(for url: URL) -> Int64? {
        100_000_000_000
    }
}

private struct NoopNotificationService: NotificationServicing {
    func requestAuthorization() async -> Bool { true }
    func notify(identifier: String, title: String, body: String) async {}
}

private final class DashboardViewModelTestClock {
    var now = Date(timeIntervalSince1970: 2_000)

    func advance(by seconds: TimeInterval) {
        now.addTimeInterval(seconds)
    }
}
