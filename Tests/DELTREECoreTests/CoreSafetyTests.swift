import Foundation
import Testing
@testable import DELTREECore

struct CoreSafetyTests {
    @Test func pinnedItemsAreNeverOneClickCleanupCandidates() {
        var item = Self.item(path: "/tmp/pinned", domain: .derivedData, kind: .derivedData)
        item.isPinned = true

        let decision = DefaultSafetyPolicy().classify(item: item, configuration: .standard, now: Date())

        #expect(decision.classification == .keep)
    }

    @Test func cleanupPlannerBlocksArchiveDomains() throws {
        let fileManager = FileManager.default
        let root = fileManager.temporaryDirectory.appendingPathComponent("DELTREE-core-\(UUID().uuidString)", isDirectory: true)
        defer { try? fileManager.removeItem(at: root) }
        try fileManager.createDirectory(at: root, withIntermediateDirectories: true)

        let archiveURL = root.appendingPathComponent("Archive.xcarchive", isDirectory: true)
        try fileManager.createDirectory(at: archiveURL, withIntermediateDirectories: true)
        var archive = Self.item(path: archiveURL.path, domain: .archives, kind: .archive)
        archive.safety = .safeToTrash

        let plan = DefaultCleanupPlanner(fileManager: fileManager).planSafeCleanup(from: StorageSnapshot(
            capturedAt: Date(),
            items: [archive],
            missingPaths: [],
            unreadablePaths: []))

        #expect(plan.actions.isEmpty)
        #expect(plan.blockedItems.map(\.path) == [archiveURL.path])
    }

    @Test func footprintAndDeltaAreAvailableThroughSwiftPMCore() {
        let now = Date()
        var old = Self.item(path: "/tmp/result", domain: .xcResults, kind: .xcResult, bytes: 100)
        old.safety = .safeToTrash
        var current = old
        current.bytes = 175
        current.attribution = .xcodeViaCodex

        let previousSnapshot = StorageSnapshot(capturedAt: now, items: [old], missingPaths: [], unreadablePaths: [])
        let currentSnapshot = StorageSnapshot(capturedAt: now, items: [current], missingPaths: [], unreadablePaths: [])

        let footprint = StorageFootprint.make(
            snapshot: currentSnapshot,
            previousSnapshot: previousSnapshot,
            availableDiskBytes: 1_000,
            lowDiskThresholdBytes: 500)
        let delta = StorageDelta.make(previous: previousSnapshot, current: currentSnapshot)

        #expect(footprint.totalBytes == 175)
        #expect(footprint.hasLowDiskSpace == false)
        #expect(delta.changedBytes == 75)
        #expect(delta.codexImpactBytes == 75)
    }

    private static func item(
        path: String,
        domain: StorageDomain,
        kind: StorageKind,
        bytes: Int64 = 1_024) -> StorageItem
    {
        StorageItem(
            id: path,
            domain: domain,
            kind: kind,
            path: path,
            displayName: URL(fileURLWithPath: path).lastPathComponent,
            bytes: bytes,
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
