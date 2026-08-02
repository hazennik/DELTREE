import Foundation
import SwiftData

extension DashboardViewModel {
    static var preview: DashboardViewModel {
        let container = try! ModelContainer(
            for: ScanHistoryRecord.self,
            CleanupHistoryRecord.self,
            AttributionEventRecord.self,
            StorageDeltaRecord.self,
            ManualOverrideRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let settings = AppSettingsStore(defaults: UserDefaults(suiteName: "preview-\(UUID().uuidString)") ?? .standard)
        let scanner = PreviewStorageScanner()
        let attributionTracker = LiveAttributionTracker()
        let viewModel = DashboardViewModel(
            scanner: scanner,
            cleanupPlanner: DefaultCleanupPlanner(),
            cleanupExecutor: DefaultCleanupExecutor(
                trashService: PreviewTrashService(),
                simctlClient: PreviewSimctlCommandClient()),
            persistence: SwiftDataSnapshotStore(container: container),
            settings: settings,
            watcher: NoopStorageWatcher(),
            rootCatalog: .live(),
            processSampler: PreviewProcessSampler(),
            attributionTracker: attributionTracker,
            diskSpaceProvider: PreviewDiskSpaceProvider(),
            notificationService: PreviewNotificationService())
        viewModel.snapshot = scanner.snapshot
        return viewModel
    }
}

private struct PreviewStorageScanner: StorageScanning {
    let snapshot = StorageSnapshot(
        capturedAt: Date(),
        items: [
            StorageItem(
                id: "/tmp/sim",
                domain: .coreSimulatorDevices,
                kind: .simulatorDevice,
                path: "/tmp/sim",
                displayName: "iPhone 16 Pro (ABCD1234)",
                bytes: 7_800_000_000,
                createdAt: Date().addingTimeInterval(-20 * 86_400),
                modifiedAt: Date().addingTimeInterval(-18 * 86_400),
                lastUsedAt: Date().addingTimeInterval(-18 * 86_400),
                attribution: .xcodeViaCodex,
                attributionConfidence: 0.8,
                safety: .safeToTrash,
                isActive: false,
                explanation: "Preview simulator data.",
                metadata: ["state": "Shutdown"]),
            StorageItem(
                id: "/tmp/dd",
                domain: .derivedData,
                kind: .derivedData,
                path: "/tmp/dd",
                displayName: "App-abc123",
                bytes: 3_400_000_000,
                createdAt: Date().addingTimeInterval(-4 * 86_400),
                modifiedAt: Date().addingTimeInterval(-2 * 86_400),
                lastUsedAt: Date().addingTimeInterval(-2 * 86_400),
                attribution: .xcode,
                attributionConfidence: 0.4,
                safety: .reviewRecommended,
                isActive: false,
                explanation: "Preview DerivedData.",
                metadata: [:]),
        ],
        missingPaths: [],
        unreadablePaths: [])

    func scan(configuration: StorageScanConfiguration, now: Date) async -> StorageSnapshot {
        snapshot
    }
}

private struct PreviewTrashService: TrashServicing {
    func moveToTrash(_ item: StorageItem) async throws {}
}

private struct PreviewSimctlCommandClient: SimctlCommanding {
    func deleteDevice(udid: String) async throws {}
    func eraseDevice(udid: String) async throws {}
}

private struct PreviewProcessSampler: ProcessSampling {
    func sample() async -> ProcessSnapshot {
        ProcessSnapshot(sampledAt: Date(), processes: [])
    }
}

private struct PreviewDiskSpaceProvider: DiskSpaceProviding {
    func availableBytes(for url: URL) -> Int64? {
        80_000_000_000
    }
}

private struct PreviewNotificationService: NotificationServicing {
    func requestAuthorization() async -> Bool { true }
    func notify(identifier: String, title: String, body: String) async {}
}

private final class NoopStorageWatcher: StorageWatching, @unchecked Sendable {
    var onChange: (@Sendable ([String]) -> Void)?
    func start(paths: [String]) {}
    func stop() {}
}
