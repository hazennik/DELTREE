import Foundation
import SwiftData
import Testing
@testable import DELTREE

@MainActor
struct SwiftDataSnapshotStoreTests {
    @Test func savesAndFetchesScanAndCleanupHistory() throws {
        let container = try ModelContainer(
            for: ScanHistoryRecord.self,
            CleanupHistoryRecord.self,
            AttributionEventRecord.self,
            StorageDeltaRecord.self,
            ManualOverrideRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = SwiftDataSnapshotStore(container: container)
        let snapshot = StorageSnapshot(
            capturedAt: Date(),
            items: [
                StorageItem(
                    id: "/tmp/item",
                    domain: .xcResults,
                    kind: .xcResult,
                    path: "/tmp/item",
                    displayName: "item",
                    bytes: 42,
                    createdAt: nil,
                    modifiedAt: nil,
                    lastUsedAt: nil,
                    attribution: .xcodeViaCodex,
                    attributionConfidence: 0.8,
                    safety: .safeToTrash,
                    isActive: false,
                    explanation: "Fixture",
                    metadata: [:]),
            ],
            missingPaths: [],
            unreadablePaths: [])

        store.saveSnapshot(snapshot)
        store.saveCleanup(
            performedAt: Date(),
            totalBytes: 42,
            itemCount: 1,
            status: "movedToTrash",
            paths: ["/tmp/item"],
            skippedPaths: [],
            errors: [:],
            initiator: "User")

        store.saveManualOverride(ManualStorageOverride(path: "/tmp/item", owner: .user, isPinned: true))

        let scan = try #require(store.recentScanRecords(limit: 1).first)
        let cleanup = try #require(store.recentCleanupRecords(limit: 1).first)

        #expect(scan.totalBytes == 42)
        #expect(scan.reclaimableBytes == 42)
        #expect(cleanup.totalBytes == 42)
        #expect(cleanup.itemCount == 1)
        #expect(cleanup.initiator == "User")
        #expect(store.manualOverrides()["/tmp/item"]?.owner == .user)
        #expect(store.manualOverrides()["/tmp/item"]?.isPinned == true)
    }
}
