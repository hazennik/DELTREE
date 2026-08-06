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
    let snapshot = PreviewStorageFixtures.snapshot

    func scan(configuration: StorageScanConfiguration, now: Date) async -> StorageSnapshot {
        snapshot
    }
}

private enum PreviewStorageFixtures {
    static let now = Date(timeIntervalSince1970: 1_785_916_800)

    static let snapshot = StorageSnapshot(
        capturedAt: now,
        items: [
            StorageItem(
                id: "/Users/developer/Library/Developer/CoreSimulator/Devices/7F1C",
                domain: .coreSimulatorDevices,
                kind: .simulatorDevice,
                path: "/Users/developer/Library/Developer/CoreSimulator/Devices/7F1C",
                displayName: "iPhone 16 Pro (7F1C)",
                bytes: 7_800_000_000,
                createdAt: daysAgo(28),
                modifiedAt: daysAgo(24),
                lastUsedAt: daysAgo(24),
                attribution: .xcodeViaCodex,
                attributionConfidence: 0.8,
                safety: .safeToTrash,
                isActive: false,
                suggestedAction: .deleteUnavailableSimulator,
                cleanupImpact: "Unavailable simulator device; safe to remove with simctl delete.",
                explanation: "Stale simulator data attributed to Codex-driven Xcode runs.",
                metadata: [
                    "state": "Shutdown",
                    "availability": "Unavailable",
                    "udid": "7F1C-PREVIEW-DEVICE",
                    "runtime": "iOS 18.5",
                    "codexTaskTitle": "Stabilize checkout UI tests",
                ]),
            StorageItem(
                id: "/Users/developer/Library/Developer/Xcode/DerivedData/Checkout-a1b2c3",
                domain: .derivedData,
                kind: .derivedData,
                path: "/Users/developer/Library/Developer/Xcode/DerivedData/Checkout-a1b2c3",
                displayName: "Checkout-a1b2c3",
                bytes: 3_400_000_000,
                createdAt: daysAgo(5),
                modifiedAt: daysAgo(2),
                lastUsedAt: daysAgo(2),
                attribution: .xcode,
                attributionConfidence: 0.4,
                safety: .reviewRecommended,
                isActive: false,
                suggestedAction: .cleanDerivedData,
                cleanupImpact: "Rebuildable Xcode cache; review before removing recent project data.",
                explanation: "Recent DerivedData with no strong Codex attribution.",
                metadata: [
                    "relatedProject": "Checkout",
                    "codexTaskTitle": "Investigate SwiftData migration",
                ]),
            StorageItem(
                id: "/Users/developer/Library/Developer/XCTestDevices/iPhone-16-Pro",
                domain: .xcTestDevices,
                kind: .xcTestDevice,
                path: "/Users/developer/Library/Developer/XCTestDevices/iPhone-16-Pro",
                displayName: "iPhone 16 Pro XCTest Device",
                bytes: 2_650_000_000,
                createdAt: daysAgo(42),
                modifiedAt: daysAgo(31),
                lastUsedAt: daysAgo(31),
                attribution: .xcodeViaCodex,
                attributionConfidence: 0.86,
                safety: .safeToTrash,
                isActive: false,
                suggestedAction: .moveToTrash,
                cleanupImpact: "Stale XCTest device data; moved to Trash.",
                explanation: "Created by automated test runs and outside the retention window.",
                metadata: [
                    "runtime": "iOS 18.4",
                    "codexTaskTitle": "Run accessibility regression suite",
                ]),
            StorageItem(
                id: "/Users/developer/Library/Developer/Xcode/DerivedData/Logs/Test/Results-App.xcresult",
                domain: .xcResults,
                kind: .xcResult,
                path: "/Users/developer/Library/Developer/Xcode/DerivedData/Logs/Test/Results-App.xcresult",
                displayName: "Results-App.xcresult",
                bytes: 1_240_000_000,
                createdAt: daysAgo(19),
                modifiedAt: daysAgo(17),
                lastUsedAt: daysAgo(17),
                attribution: .xcodeViaCodex,
                attributionConfidence: 0.74,
                safety: .safeToTrash,
                isActive: false,
                suggestedAction: .removeXCResult,
                cleanupImpact: "Old result bundle; moved to Trash after confirmation.",
                explanation: "Old XCTest logs and attachments from a Codex debugging pass.",
                metadata: [
                    "relatedProject": "DELTREE",
                    "codexTaskTitle": "Debug flaky storage table",
                ]),
            StorageItem(
                id: "/Users/developer/.codex/workspaces/deltree-audit",
                domain: .codexWorkspaces,
                kind: .codexWorkspace,
                path: "/Users/developer/.codex/workspaces/deltree-audit",
                displayName: "deltree-audit workspace",
                bytes: 980_000_000,
                createdAt: daysAgo(16),
                modifiedAt: daysAgo(12),
                lastUsedAt: daysAgo(12),
                attribution: .codex,
                attributionConfidence: 0.92,
                safety: .safeToTrash,
                isActive: false,
                suggestedAction: .removeCodexWorkspace,
                cleanupImpact: "Stale Codex workspace; moved to Trash after confirmation.",
                explanation: "Workspace belongs to a completed Codex task.",
                metadata: [
                    "codexTaskTitle": "Audit production cleanup safety",
                    "projectName": "DELTREE",
                ]),
            StorageItem(
                id: "/Users/developer/Library/Developer/CoreSimulator/Caches/dyld",
                domain: .coreSimulatorCaches,
                kind: .coreSimulatorCache,
                path: "/Users/developer/Library/Developer/CoreSimulator/Caches/dyld",
                displayName: "CoreSimulator dyld cache",
                bytes: 820_000_000,
                createdAt: daysAgo(37),
                modifiedAt: daysAgo(21),
                lastUsedAt: daysAgo(21),
                attribution: .xcode,
                attributionConfidence: 0.7,
                safety: .safeToTrash,
                isActive: false,
                suggestedAction: .moveToTrash,
                cleanupImpact: "Generated simulator cache; moved to Trash.",
                explanation: "Rebuildable simulator cache data.",
                metadata: ["runtime": "iOS 18.x"]),
            StorageItem(
                id: "/Users/developer/Library/Caches/org.swift.swiftpm",
                domain: .swiftPackageCaches,
                kind: .swiftPackageCache,
                path: "/Users/developer/Library/Caches/org.swift.swiftpm",
                displayName: "SwiftPM package cache",
                bytes: 2_100_000_000,
                createdAt: daysAgo(90),
                modifiedAt: daysAgo(3),
                lastUsedAt: daysAgo(3),
                attribution: .xcode,
                attributionConfidence: 0.46,
                safety: .probablySafe,
                isActive: false,
                suggestedAction: .moveToTrash,
                cleanupImpact: "Rebuildable cache, but may slow the next package resolve.",
                explanation: "Shared package cache used across projects.",
                metadata: ["relatedProject": "Multiple projects"]),
            StorageItem(
                id: "/Users/developer/Library/Developer/Xcode/Archives/2026-08-01/DELTREE.xcarchive",
                domain: .archives,
                kind: .archive,
                path: "/Users/developer/Library/Developer/Xcode/Archives/2026-08-01/DELTREE.xcarchive",
                displayName: "DELTREE.xcarchive",
                bytes: 12_800_000_000,
                createdAt: daysAgo(4),
                modifiedAt: daysAgo(4),
                lastUsedAt: daysAgo(4),
                attribution: .user,
                attributionConfidence: 1,
                safety: .keep,
                isActive: false,
                suggestedAction: .none,
                cleanupImpact: "",
                explanation: "Archives are protected and excluded from one-click cleanup.",
                metadata: ["relatedProject": "DELTREE"]),
            StorageItem(
                id: "/Users/developer/Library/Developer/Xcode/iOS DeviceSupport/18.5",
                domain: .deviceSupport,
                kind: .deviceSupport,
                path: "/Users/developer/Library/Developer/Xcode/iOS DeviceSupport/18.5",
                displayName: "iOS 18.5 DeviceSupport",
                bytes: 4_600_000_000,
                createdAt: daysAgo(54),
                modifiedAt: daysAgo(54),
                lastUsedAt: daysAgo(9),
                attribution: .xcode,
                attributionConfidence: 0.5,
                safety: .keep,
                isActive: false,
                suggestedAction: .none,
                cleanupImpact: "",
                explanation: "DeviceSupport is protected because it can be needed for device debugging.",
                metadata: ["runtime": "iOS 18.5"]),
            StorageItem(
                id: "/Users/developer/Library/Developer/Xcode/Products/Debug",
                domain: .xcodeProducts,
                kind: .xcodeProduct,
                path: "/Users/developer/Library/Developer/Xcode/Products/Debug",
                displayName: "Debug build products",
                bytes: 1_700_000_000,
                createdAt: daysAgo(7),
                modifiedAt: daysAgo(1),
                lastUsedAt: daysAgo(1),
                attribution: .xcode,
                attributionConfidence: 0.58,
                safety: .unknown,
                isActive: true,
                suggestedAction: .none,
                cleanupImpact: "",
                explanation: "Active build products are kept out of cleanup.",
                metadata: ["state": "Active"]),
        ],
        missingPaths: ["/Users/developer/Library/Developer/Xcode/DerivedData/MissingPreview"],
        unreadablePaths: ["/Users/developer/Library/Developer/PrivatePreview"])

    private static func daysAgo(_ days: TimeInterval) -> Date {
        now.addingTimeInterval(-days * 86_400)
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
