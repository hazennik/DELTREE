import Foundation
import Testing
@testable import DELTREE

struct StatusItemIconStateTests {
    @Test func idleHasOutlineAndNoBadge() {
        let footprint = Self.footprint(items: [], availableDiskBytes: nil, lowDiskThresholdBytes: 0)

        let state = StatusItemIconState.make(footprint: footprint, lastDelta: .empty, isScanning: false)

        #expect(state.isFilled == false)
        #expect(state.badge == .none)
    }

    @Test func scanningFillsIcon() {
        let footprint = Self.footprint(items: [], availableDiskBytes: nil, lowDiskThresholdBytes: 0)

        let state = StatusItemIconState.make(footprint: footprint, lastDelta: .empty, isScanning: true)

        #expect(state.isFilled)
        #expect(state.badge == .none)
    }

    @Test func reclaimableAddsReclaimableBadge() {
        var item = Self.item(path: "/tmp/result.xcresult", safety: .safeToTrash)
        item.suggestedAction = .removeXCResult
        let footprint = Self.footprint(items: [item], availableDiskBytes: nil, lowDiskThresholdBytes: 0)

        let state = StatusItemIconState.make(footprint: footprint, lastDelta: .empty, isScanning: false)

        #expect(state.isFilled == false)
        #expect(state.badge == .reclaimable)
    }

    @Test func warningOverridesReclaimableBadge() {
        var item = Self.item(path: "/tmp/result.xcresult", safety: .safeToTrash)
        item.suggestedAction = .removeXCResult
        let footprint = Self.footprint(items: [item], availableDiskBytes: 100, lowDiskThresholdBytes: 1_000)

        let state = StatusItemIconState.make(footprint: footprint, lastDelta: .empty, isScanning: false)

        #expect(state.badge == .warning)
    }

    private static func footprint(
        items: [StorageItem],
        availableDiskBytes: Int64?,
        lowDiskThresholdBytes: Int64) -> StorageFootprint
    {
        let snapshot = StorageSnapshot(capturedAt: Date(), items: items, missingPaths: [], unreadablePaths: [])
        return StorageFootprint.make(
            snapshot: snapshot,
            previousSnapshot: nil,
            availableDiskBytes: availableDiskBytes,
            lowDiskThresholdBytes: lowDiskThresholdBytes)
    }

    private static func item(path: String, safety: SafetyClassification) -> StorageItem {
        StorageItem(
            id: path,
            domain: .xcResults,
            kind: .xcResult,
            path: path,
            displayName: URL(fileURLWithPath: path).lastPathComponent,
            bytes: 1_000,
            createdAt: Date(),
            modifiedAt: Date(),
            lastUsedAt: Date(),
            attribution: .xcodeViaCodex,
            attributionConfidence: 0.8,
            safety: safety,
            isActive: false,
            explanation: "Fixture",
            metadata: [:])
    }
}
