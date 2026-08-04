import AppKit
import Foundation
import Observation
import UniformTypeIdentifiers

@MainActor
@Observable
final class DashboardViewModel {
    private static let minimumAutomaticScanInterval: TimeInterval = 60

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

    @ObservationIgnored private var hasStarted = false
    @ObservationIgnored private var scanTask: Task<Void, Never>?
    @ObservationIgnored private var refreshLoopTask: Task<Void, Never>?
    @ObservationIgnored private var debounceTask: Task<Void, Never>?
    @ObservationIgnored private var cleanupTask: Task<Void, Never>?
    @ObservationIgnored private var lastSnapshotFingerprint = ""
    @ObservationIgnored private var lastScanStartedAt: Date?
    @ObservationIgnored private var lastScanFinishedAt: Date?
    @ObservationIgnored private var pendingScanAfterCurrent = false
    @ObservationIgnored private var lastNotificationFingerprint = ""

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
        notificationService: any NotificationServicing)
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
        return StorageDomain.allCases.compactMap { domain in
            guard let bytes = grouped[domain], bytes > 0 else {
                return nil
            }
            return DomainSummary(
                domain: domain,
                bytes: bytes,
                itemCount: snapshot.items.filter { $0.domain == domain }.count)
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
        guard let selectedItemID else {
            return filteredItems.first
        }
        return snapshot.items.first { $0.id == selectedItemID }
    }

    func start() {
        guard hasStarted == false else {
            return
        }
        hasStarted = true
        refreshHistory()
        previousSnapshot = persistence.mostRecentSnapshot()
        configureWatcher()
        startRefreshLoop()
        scan(force: true)
    }

    func stop() {
        watcher.stop()
        scanTask?.cancel()
        refreshLoopTask?.cancel()
        debounceTask?.cancel()
        cleanupTask?.cancel()
    }

    func scan(force: Bool = true) {
        if isScanning {
            pendingScanAfterCurrent = true
            return
        }

        if force == false, let lastScanFinishedAt {
            let elapsed = Date().timeIntervalSince(lastScanFinishedAt)
            if elapsed < Self.minimumAutomaticScanInterval {
                scheduleDebouncedScan(after: Self.minimumAutomaticScanInterval - elapsed)
                return
            }
        } else if force == false, let lastScanStartedAt {
            let elapsed = Date().timeIntervalSince(lastScanStartedAt)
            if elapsed < Self.minimumAutomaticScanInterval {
                scheduleDebouncedScan(after: Self.minimumAutomaticScanInterval - elapsed)
                return
            }
        }

        let scanDate = Date()
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
                return
            }

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
            self.persistence.saveSnapshot(snapshot)
            self.persistence.saveDelta(delta)
            self.refreshHistory()
            await self.notifyIfNeeded(delta: delta, snapshot: snapshot)
            self.lastScanFinishedAt = Date()

            if self.pendingScanAfterCurrent {
                self.pendingScanAfterCurrent = false
                self.scheduleDebouncedScan(after: Self.minimumAutomaticScanInterval)
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
        scheduleDebouncedScan()
    }

    func performCleanup(_ plan: CleanupPlan) {
        cleanupTask?.cancel()
        cleanupTask = Task {
            let result = await cleanupExecutor.execute(plan)
            let completedPaths = result.completedActions.map(\.item.path)
            persistence.saveCleanup(
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
            cleanupMessage = cleanupMessage(for: result)
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
        persistence.clearManualOverride(path: item.path)
        scan(force: true)
    }

    private func configureWatcher() {
        guard settings.watcherEnabled else {
            watcher.stop()
            return
        }

        watcher.onChange = { [weak self] paths in
            Task { @MainActor [weak self] in
                await self?.handleFilesystemChange(paths: paths)
            }
        }
        watcher.start(paths: rootCatalog.watchRoots(configuration: settings.scanConfiguration))
    }

    private func handleFilesystemChange(paths: [String]) async {
        let processes = await processSampler.sample()
        await attributionTracker.recordFilesystemEvents(paths: paths, processes: processes, at: Date())

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

        persistence.saveAttributionEvent(owner: owner, confidence: confidence, paths: paths, observedAt: Date())
        if settings.autoScanAfterActivity {
            scheduleDebouncedScan()
        }
    }

    private func scheduleDebouncedScan(after seconds: TimeInterval = 2) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .seconds(seconds))
            guard Task.isCancelled == false else {
                return
            }
            scan(force: false)
        }
    }

    private func startRefreshLoop() {
        refreshLoopTask?.cancel()
        refreshLoopTask = Task {
            while Task.isCancelled == false {
                let seconds = max(60, settings.scanIntervalMinutes * 60)
                try? await Task.sleep(for: .seconds(seconds))
                guard Task.isCancelled == false else {
                    break
                }
                scan(force: false)
            }
        }
    }

    private func refreshHistory() {
        scanHistory = persistence.recentScanRecords(limit: 10)
        cleanupHistory = persistence.recentCleanupRecords(limit: 10)
        deltaHistory = persistence.recentDeltaRecords(limit: 10)
    }

    private func saveOverride(
        for item: StorageItem,
        owner: OwnerAttribution?,
        isPinned: Bool,
        isIgnored: Bool,
        note: String)
    {
        persistence.saveManualOverride(ManualStorageOverride(
            path: item.path,
            owner: owner,
            isPinned: isPinned,
            isIgnored: isIgnored,
            note: note))
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
            let data = try JSONEncoder.storage.encode(report)
            try data.write(to: url, options: [.atomic])
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
