import Foundation
import Testing
@testable import DELTREE

struct StatusMenuDescriptorTests {
    @Test func descriptorReflectsScanningGrowthAndCleanupState() {
        let now = Date()
        let item = StorageItem(
            id: "/tmp/result.xcresult",
            domain: .xcResults,
            kind: .xcResult,
            path: "/tmp/result.xcresult",
            displayName: "result.xcresult",
            bytes: 1_000,
            createdAt: now,
            modifiedAt: now,
            lastUsedAt: now,
            attribution: .xcodeViaCodex,
            attributionConfidence: 0.8,
            safety: .safeToTrash,
            isActive: false,
            explanation: "Fixture",
            metadata: [:])
        let snapshot = StorageSnapshot(capturedAt: now, items: [item], missingPaths: [], unreadablePaths: [])
        let footprint = StorageFootprint.make(
            snapshot: snapshot,
            previousSnapshot: nil,
            availableDiskBytes: 1_000,
            lowDiskThresholdBytes: 2_000)
        let delta = StorageDelta.make(previous: nil, current: snapshot)

        let descriptor = StatusMenuDescriptorBuilder.make(
            title: "Scanning...",
            footprint: footprint,
            lastDelta: delta,
            isScanning: true,
            safeItemCount: 1)

        #expect(descriptor.title == "Scanning...")
        #expect(descriptor.isWarning)
        #expect(descriptor.items.contains { item in
            if case let .overview(_, lastCodexImpactBytes, hasRecentGrowth, isScanning, safeItemCount) = item {
                return lastCodexImpactBytes == 1_000 && hasRecentGrowth && isScanning && safeItemCount == 1
            }
            return false
        })
        #expect(descriptor.items.contains(.section(title: "Storage Sources")))
        #expect(descriptor.items.contains { item in
            if case .sources = item {
                return true
            }
            return false
        })
        #expect(descriptor.items.contains(.section(title: "Top Storage Areas")))
        #expect(descriptor.items.contains { item in
            if case .breakdown = item {
                return true
            }
            return false
        })
        #expect(descriptor.items.contains(.section(title: "Cleanup Readiness")))
        #expect(descriptor.items.contains { item in
            if case let .safety(_, safeItemCount) = item {
                return safeItemCount == 1
            }
            return false
        })
        #expect(descriptor.items.contains(.command(title: "Scan Now", command: .scanNow, keyEquivalent: "r", isEnabled: false)))
        #expect(descriptor.items.contains(.command(title: "Clean Safe Items...", command: .cleanSafe, keyEquivalent: "", isEnabled: true)))
    }
}
