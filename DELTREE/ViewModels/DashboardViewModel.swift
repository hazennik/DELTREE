import AppKit
import Foundation
import Observation
import UniformTypeIdentifiers

typealias DashboardScanDelayScheduler = @MainActor (
    _ seconds: TimeInterval,
    _ operation: @escaping @MainActor () -> Void)
    -> @MainActor () -> Void

@MainActor
@Observable
final class DashboardViewModel {
    private static let memoryPressureHistoryLimit = 3
    private static let staleScanRecoveryInterval: TimeInterval = 120
    private static let filesystemChangeDebounce: Duration = .milliseconds(750)
    private static let attributionPathLimit = 200

    var snapshot: StorageSnapshot = .empty {
        didSet { onStateChange?() }
    }
    var isScanning = false {
        didSet { onStateChange?() }
    }
    var searchText = ""
    var selectedSection: DashboardSection = .overview
    var selectedDomain: StorageDomain?
    var selectedSafety: SafetyClassification?
    var selectedOwner: OwnerAttribution?
    var includeIgnoredItems = false
    var selectedItemID: StorageItem.ID?
    var pendingCleanupPlan: CleanupPlan?
    var errorMessage: String?
    var cleanupMessage: String?
    var lastDelta: StorageDelta = .empty
    var previousSnapshot: StorageSnapshot?
    var availableDiskBytes: Int64?
    var scanHistory: [ScanHistoryRecord] = []
    var cleanupHistory: [CleanupHistoryRecord] = []
    var deltaHistory: [StorageDeltaRecord] = []
    var tableSortOrder = [KeyPathComparator(\StorageItem.bytes, order: .reverse)]

    @ObservationIgnored var onStateChange: (() -> Void)?

    @ObservationIgnored private let scanner: any StorageScanning
    @ObservationIgnored private let cleanupPlanner: any CleanupPlanning
    @ObservationIgnored private let cleanupExecutor: any CleanupExecuting
    @ObservationIgnored private let persistence: any SnapshotPersisting
    @ObservationIgnored let settings: AppSettingsStore
    @ObservationIgnored private let watcher: any StorageWatching
    @ObservationIgnored private let rootCatalog: StorageRootCatalog
    @ObservationIgnored private let processSampler: any ProcessSampling
    @ObservationIgnored private let attributionTracker: any AttributionTracking
    @ObservationIgnored private let diskSpaceProvider: any DiskSpaceProviding
    @ObservationIgnored private let notificationService: any NotificationServicing
    @ObservationIgnored private let mainThreadHangWatchdog: MainThreadHangWatchdog
    @ObservationIgnored private let powerStateProvider: any PowerStateProviding
    @ObservationIgnored private let backgroundScanPolicy: BackgroundScanPolicy
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let scheduleScanDelay: DashboardScanDelayScheduler

    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private var refreshLoopTask: Task<Void, Never>?
    @ObservationIgnored private var cancelDebouncedScan: (@MainActor () -> Void)?
    @ObservationIgnored private var filesystemChangeTask: Task<Void, Never>?
    @ObservationIgnored private var cleanupTask: Task<Void, Never>?
    @ObservationIgnored private var lastSnapshotFingerprint = ""
    @ObservationIgnored private var lastScanStartedAt: Date?
    @ObservationIgnored private var lastScanFinishedAt: Date?
    @ObservationIgnored private var pendingScanAfterCurrent = false
    @ObservationIgnored private var pendingScanAfterCurrentIsForced = false
    @ObservationIgnored private var lastNotificationFingerprint = ""
    @ObservationIgnored private var pendingFilesystemChangePaths = Set<String>()
    @ObservationIgnored private var scanGeneration: UInt64 = 0
    @ObservationIgnored private var isRunning = false

    init(
        scanner: any StorageScanning,
        cleanupPlanner: any CleanupPlanning,
        cleanupExecutor: any CleanupExecuting,
        persistence: any SnapshotPersisting,
        settings: AppSettingsStore,
        watcher: any StorageWatching,
        rootCatalog: StorageRootCatalog,
        processSampler: any ProcessSampling,
        attributionTracker: any AttributionTracking,
        diskSpaceProvider: any DiskSpaceProviding,
        notificationService: any NotificationServicing,
        mainThreadHangWatchdog: MainThreadHangWatchdog = .disabled(),
        powerStateProvider: any PowerStateProviding = LivePowerStateProvider(),
        backgroundScanPolicy: BackgroundScanPolicy = .production,
        now: @escaping () -> Date = { Date() },
        scheduleScanDelay: @escaping DashboardScanDelayScheduler = DashboardViewModel.defaultScanDelayScheduler)
    {
        self.scanner = scanner
        self.cleanupPlanner = cleanupPlanner
        self.cleanupExecutor = cleanupExecutor
        self.persistence = persistence
        self.settings = settings
        self.watcher = watcher
        self.rootCatalog = rootCatalog
        self.processSampler = processSampler
        self.attributionTracker = attributionTracker
        self.diskSpaceProvider = diskSpaceProvider
        self.notificationService = notificationService
        self.mainThreadHangWatchdog = mainThreadHangWatchdog
        self.powerStateProvider = powerStateProvider
        self.backgroundScanPolicy = backgroundScanPolicy
        self.now = now
        self.scheduleScanDelay = scheduleScanDelay
    }

    var menuBarTitle: String {
        if isScanning {
            return "Scanning..."
        }
        if footprint.hasLowDiskSpace, let availableDiskBytes {
            return "Disk Low: \(StorageFormatters.byteCount(availableDiskBytes))"
        }
        if lastDelta.growthBytes >= settings.recentGrowthThresholdBytes, lastDelta.growthBytes > 0 {
            return "+\(StorageFormatters.byteCount(lastDelta.growthBytes))"
        }
        if snapshot.reclaimableBytes > 0 {
            return "Reclaimable: \(StorageFormatters.byteCount(snapshot.reclaimableBytes))"
        }
        return "DELTREE: \(StorageFormatters.byteCount(snapshot.totalBytes))"
    }

    var footprint: StorageFootprint {
        StorageFootprint.make(
            snapshot: snapshot,
            previousSnapshot: previousSnapshot,
            availableDiskBytes: availableDiskBytes,
            lowDiskThresholdBytes: settings.lowDiskThresholdBytes)
    }

    var domainSummaries: [DomainSummary] {
        let grouped = snapshot.groupedDomainTotals
        let itemCounts = snapshot.items.reduce(into: [StorageDomain: Int]()) { counts, item in
            counts[item.domain, default: 0] += 1
        }
        return StorageDomain.allCases.compactMap { domain in
            guard let bytes = grouped[domain], bytes > 0 else {
                return nil
            }
            return DomainSummary(
                domain: domain,
                bytes: bytes,
                itemCount: itemCounts[domain] ?? 0)
        }
        .sorted { lhs, rhs in
            if lhs.bytes == rhs.bytes {
                return lhs.domain.displayName.localizedStandardCompare(rhs.domain.displayName) == .orderedAscending
            }
            return lhs.bytes > rhs.bytes
        }
    }

    var filteredItems: [StorageItem] {
        let sectionDomains = selectedDomain == nil ? selectedSection.domains : nil
        let filtered = snapshot.items.filter { item in
            guard includeIgnoredItems || item.isIgnored == false else {
                return false
            }
            let matchesDomain = selectedDomain.map { item.domain == $0 } ?? true
            let matchesSection = sectionDomains.map { $0.contains(item.domain) } ?? true
            let matchesSafety = selectedSafety.map { item.safety == $0 } ?? true
            let matchesOwner = selectedOwner.map { item.attribution == $0 } ?? true
            let matchesSearch = searchText.isEmpty ||
                item.displayName.localizedCaseInsensitiveContains(searchText) ||
                item.path.localizedCaseInsensitiveContains(searchText) ||
                item.kind.displayName.localizedCaseInsensitiveContains(searchText) ||
                item.attribution.displayName.localizedCaseInsensitiveContains(searchText) ||
                item.relatedProject.localizedCaseInsensitiveContains(searchText) ||
                item.relatedCodexTask.localizedCaseInsensitiveContains(searchText)
            return matchesDomain && matchesSection && matchesSafety && matchesOwner && matchesSearch
        }
        return filtered.sorted(using: tableSortOrder)
    }

    var selectedItem: StorageItem? {
        let visibleItems = filteredItems
        guard let selectedItemID else {
            return visibleItems.first
        }
        return visibleItems.first { $0.id == selectedItemID } ?? visibleItems.first
    }

    func start() {
        guard hasStarted == false else {
            return
        }
        hasStarted = true
        isRunning = true
        refreshHistory()
        let cachedSnapshot = persistence.mostRecentSnapshot()
        previousSnapshot = cachedSnapshot
        if let cachedSnapshot {
            snapshot = cachedSnapshot
            lastSnapshotFingerprint = cachedSnapshot.displayFingerprint
        }
        configureWatcher()
        startRefreshLoop()
        scan(force: true)
    }

    func stop() {
        isRunning = false
        watcher.stop()
        scanTask?.cancel()
        refreshLoopTask?.cancel()
        cancelDebouncedScan?()
        cancelDebouncedScan = nil
        cancelPendingFilesystemChanges()
        cleanupTask?.cancel()
    }

    @discardableResult
    func trimTransientStateForMemoryPressure(level: MemoryPressureLevel) -> MemoryPressureTrimSummary {
        let releasedPreviousSnapshot = previousSnapshot != nil
        previousSnapshot = nil

        return MemoryPressureTrimSummary(
            level: level,
            releasedPreviousSnapshot: releasedPreviousSnapshot,
            scanHistoryTrimmedCount: trimHistory(&scanHistory, keeping: Self.memoryPressureHistoryLimit),
            cleanupHistoryTrimmedCount: trimHistory(&cleanupHistory, keeping: Self.memoryPressureHistoryLimit),
            deltaHistoryTrimmedCount: trimHistory(&deltaHistory, keeping: Self.memoryPressureHistoryLimit),
            diagnosticsTrimmedCount: 0)
    }

    func scan(force: Bool = true) {
        if isScanning {
            if force, activeScanIsStale() {
                recoverFromStaleScan()
            } else {
                pendingScanAfterCurrent = true
                pendingScanAfterCurrentIsForced = pendingScanAfterCurrentIsForced || force
                return
            }
        }

        if force == false, let delay = automaticScanDelaySinceMostRecentScan() {
            scheduleDebouncedScan(after: delay)
            return
        }

        let scanDate = now()
        scanGeneration &+= 1
        let generation = scanGeneration
        watcher.stop()
        cancelPendingFilesystemChanges()
        lastScanStartedAt = scanDate
        isScanning = true
        errorMessage = nil
        var configuration = settings.scanConfiguration
        configuration.manualOverrides = persistence.manualOverrides()
        let scanner = scanner
        let diskSpaceProvider = diskSpaceProvider
        let previousSnapshot = persistence.mostRecentSnapshot()

        scanTask = Task {
            let snapshot = await scanner.scan(configuration: configuration, now: scanDate)

            guard Task.isCancelled == false else {
                self.finishCancelledScan(generation: generation)
                return
            }
            guard self.scanGeneration == generation else {
                return
            }

            let delta = mainThreadHangWatchdog.withBreadcrumb("scan.apply") {
                self.previousSnapshot = previousSnapshot
                self.availableDiskBytes = diskSpaceProvider.availableBytes(for: URL(fileURLWithPath: NSHomeDirectory(), isDirectory: true))
                let delta = StorageDelta.make(previous: previousSnapshot, current: snapshot)
                self.lastDelta = delta
                let fingerprint = snapshot.displayFingerprint
                if fingerprint != self.lastSnapshotFingerprint {
                    self.snapshot = snapshot
                    self.lastSnapshotFingerprint = fingerprint
                }
                self.isScanning = false
                return delta
            }
            await Task.yield()
            guard self.scanGeneration == generation else {
                return
            }
            do {
                try mainThreadHangWatchdog.withBreadcrumb("persistence.scan") {
                    try self.persistence.saveSnapshot(snapshot)
                    try self.persistence.saveDelta(delta)
                    self.refreshHistory()
                }
            } catch {
                self.errorMessage = "Could not save scan history: \(error.localizedDescription)"
            }
            await self.notifyIfNeeded(delta: delta, snapshot: snapshot)
            self.lastScanFinishedAt = self.now()
            self.scanTask = nil
            if self.isRunning {
                self.configureWatcher()
            }

            if self.pendingScanAfterCurrent {
                let forcePendingScan = self.pendingScanAfterCurrentIsForced
                self.pendingScanAfterCurrent = false
                self.pendingScanAfterCurrentIsForced = false
                if forcePendingScan {
                    self.scan(force: true)
                } else {
                    self.scheduleDebouncedScan(after: self.backgroundScanInterval())
                }
            }
        }
    }

    func prepareSafeCleanup() {
        let plan = cleanupPlanner.planSafeCleanup(from: snapshot)
        pendingCleanupPlan = plan
    }

    func prepareCleanup(for item: StorageItem, action: StorageAction) {
        pendingCleanupPlan = cleanupPlanner.planCleanup(for: item, action: action, in: snapshot)
    }

    func settingsDidChange() {
        if settings.notificationsEnabled {
            Task {
                _ = await notificationService.requestAuthorization()
            }
        }
        configureWatcher()
        startRefreshLoop()
        scheduleBackgroundScan()
    }

    func performCleanup(_ plan: CleanupPlan) {
        cleanupTask?.cancel()
        cleanupTask = Task {
            mainThreadHangWatchdog.recordBreadcrumb("cleanup.execute.begin")
            let result = await cleanupExecutor.execute(plan)
            mainThreadHangWatchdog.recordBreadcrumb("cleanup.execute.end")
            let completedPaths = result.completedActions.map(\.item.path)
            var message = cleanupMessage(for: result)
            do {
                try mainThreadHangWatchdog.withBreadcrumb("persistence.cleanup") {
                    try persistence.saveCleanup(
                        performedAt: result.performedAt,
                        totalBytes: result.reclaimedBytes,
                        itemCount: completedPaths.count,
                        status: result.status,
                        paths: completedPaths,
                        skippedPaths: result.skippedItems.map(\.path),
                        errors: Dictionary(uniqueKeysWithValues: result.failedActions.map { action, message in
                            (action.item.path, message)
                        }),
                        initiator: "User")
                }
            } catch {
                message += " Could not save cleanup history: \(error.localizedDescription)"
            }
            cleanupMessage = message
            pendingCleanupPlan = nil
            refreshHistory()
            await notifyCleanupComplete(result)
            scan(force: true)
        }
    }

    func exportCleanupReport(plan: CleanupPlan) {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "DELTREE-Cleanup-\(Int(Date().timeIntervalSince1970)).json"
        panel.allowedContentTypes = [.json]
        panel.canCreateDirectories = true
        panel.begin { [weak self] response in
            guard response == .OK, let url = panel.url else {
                return
            }
            self?.writeCleanupReport(plan: plan, to: url)
        }
    }

    func reveal(_ item: StorageItem) {
        NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: item.path)])
    }

    func copyPath(_ item: StorageItem) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(item.path, forType: .string)
    }

    func markUserOwned(_ item: StorageItem) {
        saveOverride(for: item, owner: .user, isPinned: item.isPinned, isIgnored: item.isIgnored, note: "Marked user-owned")
    }

    func togglePinned(_ item: StorageItem) {
        saveOverride(for: item, owner: item.attribution, isPinned: item.isPinned == false, isIgnored: item.isIgnored, note: "Pin toggle")
    }

    func toggleIgnored(_ item: StorageItem) {
        saveOverride(for: item, owner: item.attribution, isPinned: item.isPinned, isIgnored: item.isIgnored == false, note: "Ignore toggle")
    }

    func resetAttribution(_ item: StorageItem) {
        do {
            try mainThreadHangWatchdog.withBreadcrumb("persistence.override.clear") {
                try persistence.clearManualOverride(path: item.path)
            }
        } catch {
            cleanupMessage = "Could not reset attribution: \(error.localizedDescription)"
        }
        scan(force: true)
    }

    private func configureWatcher() {
        guard settings.watcherEnabled else {
            watcher.stop()
            cancelPendingFilesystemChanges()
            return
        }

        watcher.onChange = { [weak self] paths in
            Task { @MainActor [weak self] in
                self?.queueFilesystemChange(paths: paths)
            }
        }
        watcher.start(paths: rootCatalog.watchRoots(configuration: settings.scanConfiguration))
    }

    private func activeScanIsStale() -> Bool {
        guard let lastScanStartedAt else {
            return false
        }
        return now().timeIntervalSince(lastScanStartedAt) >= Self.staleScanRecoveryInterval
    }

    private func recoverFromStaleScan() {
        scanGeneration &+= 1
        scanTask?.cancel()
        scanTask = nil
        pendingScanAfterCurrent = false
        pendingScanAfterCurrentIsForced = false
        isScanning = false
    }

    private func finishCancelledScan(generation: UInt64) {
        guard scanGeneration == generation else {
            return
        }
        isScanning = false
        scanTask = nil
        if isRunning {
            configureWatcher()
        }
    }

    private func queueFilesystemChange(paths: [String]) {
        guard paths.isEmpty == false, isRunning else {
            return
        }
        pendingFilesystemChangePaths.formUnion(paths)
        filesystemChangeTask?.cancel()
        filesystemChangeTask = Task { @MainActor [weak self] in
            do {
                try await Task.sleep(for: Self.filesystemChangeDebounce)
            } catch {
                return
            }
            guard Task.isCancelled == false else {
                return
            }
            await self?.processQueuedFilesystemChanges()
        }
    }

    private func processQueuedFilesystemChanges() async {
        let paths = limitedAttributionPaths(from: pendingFilesystemChangePaths)
        pendingFilesystemChangePaths.removeAll(keepingCapacity: true)
        filesystemChangeTask = nil
        guard paths.isEmpty == false else {
            return
        }
        await handleFilesystemChange(paths: paths)
    }

    private func cancelPendingFilesystemChanges() {
        filesystemChangeTask?.cancel()
        filesystemChangeTask = nil
        pendingFilesystemChangePaths.removeAll(keepingCapacity: true)
    }

    private func limitedAttributionPaths(from paths: Set<String>) -> [String] {
        let sortedPaths = paths.sorted()
        guard sortedPaths.count > Self.attributionPathLimit else {
            return sortedPaths
        }
        return Array(sortedPaths.prefix(Self.attributionPathLimit))
    }

    private func handleFilesystemChange(paths: [String]) async {
        let processes = await processSampler.sample()
        await attributionTracker.recordFilesystemEvents(paths: paths, processes: processes, at: now())

        let owner: OwnerAttribution
        let confidence: Double
        if processes.hasCodexActivity && processes.hasXcodeActivity {
            owner = .xcodeViaCodex
            confidence = 0.8
        } else if processes.hasCodexActivity {
            owner = .codex
            confidence = 0.7
        } else if processes.hasXcodeActivity {
            owner = .xcode
            confidence = 0.6
        } else {
            owner = .unknown
            confidence = 0.0
        }

        if confidence > 0 {
            do {
                try mainThreadHangWatchdog.withBreadcrumb("persistence.attribution") {
                    try persistence.saveAttributionEvent(owner: owner, confidence: confidence, paths: paths, observedAt: now())
                }
            } catch {
                errorMessage = "Could not save attribution history: \(error.localizedDescription)"
            }
        }
        if settings.autoScanAfterActivity {
            scheduleBackgroundScan()
        }
    }

    private func scheduleBackgroundScan() {
        scheduleDebouncedScan(after: backgroundScanInterval())
    }

    private func scheduleDebouncedScan(after seconds: TimeInterval) {
        cancelDebouncedScan?()
        cancelDebouncedScan = scheduleScanDelay(max(0, seconds)) { [weak self] in
            self?.scan(force: false)
        }
    }

    private func startRefreshLoop() {
        refreshLoopTask?.cancel()
        refreshLoopTask = Task {
            while Task.isCancelled == false {
                let seconds = backgroundScanInterval()
                try? await Task.sleep(for: .seconds(seconds))
                guard Task.isCancelled == false else {
                    break
                }
                scan(force: false)
            }
        }
    }

    private func automaticScanDelaySinceMostRecentScan() -> TimeInterval? {
        let minimumInterval = backgroundScanInterval()
        let referenceDate = lastScanFinishedAt ?? lastScanStartedAt
        guard let referenceDate else {
            return nil
        }

        let elapsed = now().timeIntervalSince(referenceDate)
        guard elapsed < minimumInterval else {
            return nil
        }
        return minimumInterval - elapsed
    }

    private func backgroundScanInterval() -> TimeInterval {
        backgroundScanPolicy.effectiveInterval(
            userInterval: settings.scanIntervalMinutes * 60,
            powerState: powerStateProvider.currentPowerState)
    }

    private static func defaultScanDelayScheduler(
        seconds: TimeInterval,
        operation: @escaping @MainActor () -> Void)
        -> @MainActor () -> Void
    {
        let task = Task { @MainActor in
            if seconds > 0 {
                try? await Task.sleep(for: .seconds(seconds))
            }
            guard Task.isCancelled == false else {
                return
            }
            operation()
        }
        return {
            task.cancel()
        }
    }

    private func refreshHistory() {
        scanHistory = persistence.recentScanRecords(limit: 10)
        cleanupHistory = persistence.recentCleanupRecords(limit: 10)
        deltaHistory = persistence.recentDeltaRecords(limit: 10)
    }

    private func trimHistory<Element>(_ records: inout [Element], keeping limit: Int) -> Int {
        let trimmedCount = max(0, records.count - limit)
        if trimmedCount > 0 {
            records.removeLast(trimmedCount)
        }
        return trimmedCount
    }

    private func saveOverride(
        for item: StorageItem,
        owner: OwnerAttribution?,
        isPinned: Bool,
        isIgnored: Bool,
        note: String)
    {
        do {
            try mainThreadHangWatchdog.withBreadcrumb("persistence.override") {
                try persistence.saveManualOverride(ManualStorageOverride(
                    path: item.path,
                    owner: owner,
                    isPinned: isPinned,
                    isIgnored: isIgnored,
                    note: note))
            }
        } catch {
            cleanupMessage = "Could not save override: \(error.localizedDescription)"
        }
        scan(force: true)
    }

    private func cleanupMessage(for result: CleanupExecutionResult) -> String {
        let actionCount = result.completedActions.count
        if result.failedActions.isEmpty {
            return "Completed \(actionCount) cleanup action(s), reclaiming \(StorageFormatters.byteCount(result.reclaimedBytes))."
        }
        return "Completed \(actionCount) cleanup action(s); \(result.failedActions.count) failed."
    }

    private func writeCleanupReport(plan: CleanupPlan, to url: URL) {
        let report = CleanupReport(
            createdAt: Date(),
            snapshotCapturedAt: snapshot.capturedAt,
            totalBytes: snapshot.totalBytes,
            reclaimableBytes: plan.reclaimableBytes,
            actions: plan.actions.map { action in
                CleanupReport.Action(
                    path: action.item.path,
                    displayName: action.item.displayName,
                    domain: action.item.domain.displayName,
                    bytes: action.item.bytes,
                    safety: action.item.safety.displayName,
                    owner: action.item.attribution.displayName,
                    action: action.action.displayName,
                    reason: action.reason)
            },
            blockedPaths: plan.blockedItems.map(\.path),
            unreadablePaths: snapshot.unreadablePaths,
            missingPaths: snapshot.missingPaths)

        do {
            let data = try mainThreadHangWatchdog.withBreadcrumb("report.encode") {
                try JSONEncoder.storage.encode(report)
            }
            try mainThreadHangWatchdog.withBreadcrumb("report.write") {
                try data.write(to: url, options: [.atomic])
            }
            cleanupMessage = "Exported cleanup report."
        } catch {
            cleanupMessage = "Could not export cleanup report: \(error.localizedDescription)"
        }
    }

    private func notifyIfNeeded(delta: StorageDelta, snapshot: StorageSnapshot) async {
        guard settings.notificationsEnabled else {
            return
        }

        let fingerprint = "\(delta.id)-\(snapshot.reclaimableBytes)-\(footprint.hasLowDiskSpace)"
        guard fingerprint != lastNotificationFingerprint else {
            return
        }
        lastNotificationFingerprint = fingerprint

        if delta.codexImpactBytes >= settings.recentGrowthThresholdBytes, delta.codexImpactBytes > 0 {
            await notificationService.notify(
                identifier: "deltree-growth-\(delta.id.uuidString)",
                title: "Codex/Xcode Storage Grew",
                body: "\(StorageFormatters.byteCount(delta.codexImpactBytes)) was added or expanded since the last scan.")
        }

        let staleXCTestDevices = snapshot.items.filter { $0.domain == .xcTestDevices && $0.safety == .safeToTrash }
        if staleXCTestDevices.isEmpty == false {
            await notificationService.notify(
                identifier: "deltree-stale-xctest-\(snapshot.capturedAt.timeIntervalSince1970)",
                title: "Stale XCTest Devices Found",
                body: "\(staleXCTestDevices.count) test device item(s) look safe to remove.")
        }

        if footprint.hasLowDiskSpace, let availableDiskBytes {
            await notificationService.notify(
                identifier: "deltree-low-disk-\(snapshot.capturedAt.timeIntervalSince1970)",
                title: "Disk Space Is Low",
                body: "\(StorageFormatters.byteCount(availableDiskBytes)) is available on this volume.")
        }

        let newRuntimeItems = delta.newItems.filter { $0.domain == .simulatorRuntimes || $0.domain == .simulatorImages }
        if newRuntimeItems.isEmpty == false {
            await notificationService.notify(
                identifier: "deltree-new-runtime-\(delta.id.uuidString)",
                title: "New Simulator Component Detected",
                body: "\(newRuntimeItems.count) runtime/image item(s) appeared since the last scan.")
        }
    }

    private func notifyCleanupComplete(_ result: CleanupExecutionResult) async {
        guard settings.notificationsEnabled else {
            return
        }

        await notificationService.notify(
            identifier: "deltree-cleanup-\(result.performedAt.timeIntervalSince1970)",
            title: "DELTREE Cleanup Complete",
            body: "\(result.completedActions.count) action(s), \(StorageFormatters.byteCount(result.reclaimedBytes)) reclaimed.")
    }
}

struct CleanupReport: Codable, Sendable {
    struct Action: Codable, Sendable {
        var path: String
        var displayName: String
        var domain: String
        var bytes: Int64
        var safety: String
        var owner: String
        var action: String
        var reason: String
    }

    var createdAt: Date
    var snapshotCapturedAt: Date
    var totalBytes: Int64
    var reclaimableBytes: Int64
    var actions: [Action]
    var blockedPaths: [String]
    var unreadablePaths: [String]
    var missingPaths: [String]
}
