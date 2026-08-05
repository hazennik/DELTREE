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
        let snapshot = Self.snapshot(capturedAt: Date(), path: "/tmp/item", bytes: 42)

        try store.saveSnapshot(snapshot)
        try store.saveCleanup(
            performedAt: Date(),
            totalBytes: 42,
            itemCount: 1,
            status: "movedToTrash",
            paths: ["/tmp/item"],
            skippedPaths: [],
            errors: [:],
            initiator: "User")

        try store.saveManualOverride(ManualStorageOverride(path: "/tmp/item", owner: .user, isPinned: true))

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

    @Test func prunesOperationalHistoryRecords() throws {
        let container = try ModelContainer(
            for: ScanHistoryRecord.self,
            CleanupHistoryRecord.self,
            AttributionEventRecord.self,
            StorageDeltaRecord.self,
            ManualOverrideRecord.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let store = SwiftDataSnapshotStore(
            container: container,
            retentionLimits: .init(
                scanHistory: 2,
                deltaHistory: 2,
                cleanupHistory: 1,
                attributionEvents: 1))
        let start = Date(timeIntervalSince1970: 1_700_000_000)

        for index in 0..<4 {
            let date = start.addingTimeInterval(Double(index))
            let path = "/tmp/item-\(index)"
            let snapshot = Self.snapshot(capturedAt: date, path: path, bytes: Int64(index + 1))
            try store.saveSnapshot(snapshot)
            try store.saveDelta(StorageDelta(
                fromDate: nil,
                toDate: date,
                addedBytes: Int64(index + 1),
                changedBytes: 0,
                removedBytes: 0,
                newItems: snapshot.items,
                changedItems: [],
                removedPaths: []))
            try store.saveCleanup(
                performedAt: date,
                totalBytes: Int64(index + 1),
                itemCount: 1,
                status: "completed",
                paths: [path],
                skippedPaths: [],
                errors: [:],
                initiator: "User")
            try store.saveAttributionEvent(owner: .codex, confidence: 0.9, paths: [path], observedAt: date)
        }

        #expect(store.recentScanRecords(limit: 10).map(\.totalBytes) == [4, 3])
        #expect(store.recentDeltaRecords(limit: 10).map(\.addedBytes) == [4, 3])
        #expect(store.recentCleanupRecords(limit: 10).map(\.totalBytes) == [4])

        let attributionRecords = (try? ModelContext(container).fetch(FetchDescriptor<AttributionEventRecord>())) ?? []
        #expect(attributionRecords.count == 1)
        #expect(attributionRecords.first?.confidence == 0.9)
    }

    private static func snapshot(capturedAt: Date, path: String, bytes: Int64) -> StorageSnapshot {
        StorageSnapshot(
            capturedAt: capturedAt,
            items: [
                StorageItem(
                    id: path,
                    domain: .xcResults,
                    kind: .xcResult,
                    path: path,
                    displayName: URL(fileURLWithPath: path).lastPathComponent,
                    bytes: bytes,
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
    }
}
