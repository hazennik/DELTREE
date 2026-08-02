import Foundation
import Testing
@testable import DELTREE

struct StorageFootprintAndDeltaTests {
    @Test func footprintGroupsDomainsAndFlagsLowDisk() {
        let now = Date()
        var codex = Self.item(
            path: "/tmp/codex",
            domain: .codexWorkspaces,
            kind: .codexWorkspace,
            bytes: 4_000,
            attribution: .codex,
            safety: .safeToTrash,
            now: now)
        codex.suggestedAction = .removeCodexWorkspace

        let xcode = Self.item(
            path: "/tmp/derived",
            domain: .derivedData,
            kind: .derivedData,
            bytes: 6_000,
            attribution: .xcodeViaCodex,
            safety: .reviewRecommended,
            now: now)

        let snapshot = StorageSnapshot(
            capturedAt: now,
            items: [codex, xcode],
            missingPaths: ["/tmp/missing"],
            unreadablePaths: ["/tmp/unreadable"])

        let footprint = StorageFootprint.make(
            snapshot: snapshot,
            previousSnapshot: nil,
            availableDiskBytes: 500,
            lowDiskThresholdBytes: 1_000)

        #expect(footprint.totalBytes == 10_000)
        #expect(footprint.reclaimableBytes == 4_000)
        #expect(footprint.codexAttributedBytes == 10_000)
        #expect(footprint.xcodeRelatedBytes == 6_000)
        #expect(footprint.hasLowDiskSpace)
        #expect(footprint.domainBreakdowns.map(\.domain) == [.derivedData, .codexWorkspaces])
        #expect(footprint.missingPaths == ["/tmp/missing"])
        #expect(footprint.unreadablePaths == ["/tmp/unreadable"])
    }

    @Test func deltaTracksNewChangedAndRemovedItems() {
        let now = Date()
        let previousItem = Self.item(path: "/tmp/a", domain: .xcResults, kind: .xcResult, bytes: 100, attribution: .xcode, safety: .safeToTrash, now: now)
        let removedItem = Self.item(path: "/tmp/removed", domain: .derivedData, kind: .derivedData, bytes: 500, attribution: .xcode, safety: .reviewRecommended, now: now)
        let changedItem = Self.item(path: "/tmp/a", domain: .xcResults, kind: .xcResult, bytes: 150, attribution: .xcodeViaCodex, safety: .safeToTrash, now: now)
        let newItem = Self.item(path: "/tmp/new", domain: .codexWorkspaces, kind: .codexWorkspace, bytes: 200, attribution: .codex, safety: .safeToTrash, now: now)

        let previous = StorageSnapshot(capturedAt: now, items: [previousItem, removedItem], missingPaths: [], unreadablePaths: [])
        let current = StorageSnapshot(capturedAt: now, items: [changedItem, newItem], missingPaths: [], unreadablePaths: [])

        let delta = StorageDelta.make(previous: previous, current: current)

        #expect(delta.addedBytes == 200)
        #expect(delta.changedBytes == 50)
        #expect(delta.removedBytes == 500)
        #expect(delta.growthBytes == 250)
        #expect(delta.codexImpactBytes == 250)
        #expect(delta.newItems.map(\.path) == ["/tmp/new"])
        #expect(delta.removedPaths == ["/tmp/removed"])
    }

    private static func item(
        path: String,
        domain: StorageDomain,
        kind: StorageKind,
        bytes: Int64,
        attribution: OwnerAttribution,
        safety: SafetyClassification,
        now: Date) -> StorageItem
    {
        StorageItem(
            id: path,
            domain: domain,
            kind: kind,
            path: path,
            displayName: URL(fileURLWithPath: path).lastPathComponent,
            bytes: bytes,
            createdAt: now,
            modifiedAt: now,
            lastUsedAt: now,
            attribution: attribution,
            attributionConfidence: 0.9,
            safety: safety,
            isActive: false,
            explanation: "Fixture",
            metadata: [:])
    }
}
