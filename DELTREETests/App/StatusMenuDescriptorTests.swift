import AppKit
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
            safeItemCount: 1,
            cleanupSuggestions: [StatusMenuCleanupSuggestion.make(from: item)])

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
        #expect(descriptor.items.contains(.section(title: "Suggested Cleanup")))
        #expect(descriptor.items.contains { item in
            if case let .cleanupSuggestions(suggestions, totalCount, totalBytes) = item {
                return suggestions.map(\.title) == ["result.xcresult"] &&
                    suggestions.first?.consequence == "Removes old test logs and attachments." &&
                    totalCount == 1 &&
                    totalBytes == 1_000
            }
            return false
        })
        #expect(descriptor.items.contains(.command(title: "Scan Now", command: .scanNow, keyEquivalent: "r", isEnabled: false)))
        #expect(descriptor.items.contains(.command(title: "Clean Safe Items...", command: .cleanSafe, keyEquivalent: "", isEnabled: true)))
        #expect(descriptor.items.contains { item in
            if case let .command(_, command, _, _) = item {
                return command == .checkForUpdates
            }
            return false
        } == false)
    }

    @Test func descriptorSuppressesMenuCleanupWhenNotifyOnlyIsEnabled() {
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
            availableDiskBytes: 10_000,
            lowDiskThresholdBytes: 1_000)

        let descriptor = StatusMenuDescriptorBuilder.make(
            title: "DELTREE",
            footprint: footprint,
            lastDelta: StorageDelta.make(previous: nil, current: snapshot),
            isScanning: false,
            safeItemCount: 1,
            allowsMenuCleanup: false,
            cleanupSuggestions: [StatusMenuCleanupSuggestion.make(from: item)])

        #expect(descriptor.items.contains(.section(title: "Suggested Cleanup")) == false)
        #expect(descriptor.items.contains(.command(title: "Clean Safe Items...", command: .cleanSafe, keyEquivalent: "", isEnabled: false)))
    }

    @Test func descriptorShowsAvailableManualUpdateCheck() {
        let descriptor = StatusMenuDescriptorBuilder.make(
            title: "DELTREE",
            footprint: StorageFootprint.make(
                snapshot: .empty,
                previousSnapshot: nil,
                availableDiskBytes: nil,
                lowDiskThresholdBytes: 0),
            lastDelta: .empty,
            isScanning: false,
            safeItemCount: 0,
            showsUpdateCheck: true,
            canCheckForUpdates: true)

        #expect(descriptor.items.contains(.command(
            title: "Check for Updates...",
            command: .checkForUpdates,
            keyEquivalent: "",
            isEnabled: true)))
    }

    @Test func descriptorDisablesManualUpdateCheckUntilUpdaterIsReady() {
        let descriptor = StatusMenuDescriptorBuilder.make(
            title: "DELTREE",
            footprint: StorageFootprint.make(
                snapshot: .empty,
                previousSnapshot: nil,
                availableDiskBytes: nil,
                lowDiskThresholdBytes: 0),
            lastDelta: .empty,
            isScanning: false,
            safeItemCount: 0,
            showsUpdateCheck: true,
            canCheckForUpdates: false)

        #expect(descriptor.items.contains(.command(
            title: "Check for Updates...",
            command: .checkForUpdates,
            keyEquivalent: "",
            isEnabled: false)))
    }

    @Test func descriptorSortsReviewItemsBySize() {
        let smaller = StatusMenuReviewItem(
            id: "smaller",
            title: "Smaller",
            path: "/tmp/smaller",
            domain: .xcResults,
            bytes: 100)
        let larger = StatusMenuReviewItem(
            id: "larger",
            title: "Larger",
            path: "/tmp/larger",
            domain: .derivedData,
            bytes: 300)
        let descriptor = StatusMenuDescriptorBuilder.make(
            title: "DELTREE",
            footprint: StorageFootprint.make(
                snapshot: .empty,
                previousSnapshot: nil,
                availableDiskBytes: nil,
                lowDiskThresholdBytes: 0),
            lastDelta: .empty,
            isScanning: false,
            safeItemCount: 0,
            reviewItems: [smaller, larger])

        #expect(descriptor.items.contains(.section(title: "Cleanup Readiness")))
        #expect(descriptor.items.contains(.reviewItems(
            items: [larger, smaller],
            totalBytes: 400)))
    }

    @MainActor
    @Test func rendererBuildsReviewHoverSubmenu() {
        let reviewItem = StatusMenuReviewItem(
            id: "review",
            title: "Build Cache",
            path: "/tmp/review",
            domain: .derivedData,
            bytes: 300)
        let descriptor = StatusMenuDescriptor(
            title: "DELTREE",
            isWarning: false,
            items: [.reviewItems(items: [reviewItem], totalBytes: 300)])
        let menu = NSMenu()
        let target = StatusMenuTestTarget()

        StatusMenuRenderer.render(
            descriptor: descriptor,
            visualMode: .modern,
            into: menu,
            target: target,
            actionSelector: #selector(StatusMenuTestTarget.performMenuCommand(_:)))

        let submenuItem = menu.items.first
        #expect(submenuItem?.title == "Review Items (1)")
        #expect(submenuItem?.submenu?.items.first?.title == "Build Cache (300 bytes)")
        #expect(submenuItem?.submenu?.items.first?.toolTip == "/tmp/review")
        #expect(submenuItem?.submenu?.items.first?.representedObject as? StatusMenuAction == .reviewItem("review"))
    }
}

@MainActor
private final class StatusMenuTestTarget: NSObject {
    @objc func performMenuCommand(_ item: NSMenuItem) {}
}
