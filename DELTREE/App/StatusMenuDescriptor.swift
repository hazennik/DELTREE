import Foundation

enum StatusMenuCommand: String, Hashable, Sendable {
    case openDashboard
    case scanNow
    case cleanSafe
    case openSettings
    case checkForUpdates
    case quit

    var systemImage: String {
        switch self {
        case .openDashboard:
            "rectangle.grid.2x2"
        case .scanNow:
            "arrow.clockwise"
        case .cleanSafe:
            "trash"
        case .openSettings:
            "gearshape"
        case .checkForUpdates:
            "arrow.down.circle"
        case .quit:
            "power"
        }
    }
}

enum StatusMenuAction: Hashable, Sendable {
    case command(StatusMenuCommand)
    case reviewItem(StorageItem.ID)
}

enum StatusMenuItemDescriptor: Hashable, Sendable {
    case overview(
        footprint: StorageFootprint,
        lastCodexImpactBytes: Int64,
        hasRecentGrowth: Bool,
        isScanning: Bool,
        safeItemCount: Int)
    case section(title: String)
    case summary(title: String, value: String, systemImage: String?)
    case sources(StorageFootprint)
    case breakdown(StorageFootprint)
    case cleanupSuggestions(suggestions: [StatusMenuCleanupSuggestion], totalCount: Int, totalBytes: Int64)
    case safety(footprint: StorageFootprint, safeItemCount: Int)
    case reviewItems(items: [StatusMenuReviewItem], totalBytes: Int64)
    case separator
    case command(title: String, command: StatusMenuCommand, keyEquivalent: String, isEnabled: Bool)
}

struct StatusMenuDescriptor: Hashable, Sendable {
    var title: String
    var isWarning: Bool
    var items: [StatusMenuItemDescriptor]
}

enum StatusMenuDescriptorBuilder {
    static func make(
        title: String,
        footprint: StorageFootprint,
        lastDelta: StorageDelta,
        isScanning: Bool,
        safeItemCount: Int,
        allowsMenuCleanup: Bool = true,
        showsUpdateCheck: Bool = false,
        canCheckForUpdates: Bool = false,
        reviewItems: [StatusMenuReviewItem] = [],
        cleanupSuggestions: [StatusMenuCleanupSuggestion] = []) -> StatusMenuDescriptor
    {
        var items: [StatusMenuItemDescriptor] = [
            .overview(
                footprint: footprint,
                lastCodexImpactBytes: lastDelta.codexImpactBytes,
                hasRecentGrowth: lastDelta.growthBytes > 0,
                isScanning: isScanning,
                safeItemCount: safeItemCount),
        ]

        if footprint.domainBreakdowns.isEmpty == false {
            items.append(.separator)
            items.append(.section(title: "Storage Sources"))
            items.append(.sources(footprint))
            items.append(.separator)
            items.append(.section(title: "Top Storage Areas"))
            items.append(.breakdown(footprint))
        }

        if footprint.reclaimableBytes > 0 || footprint.reviewBytes > 0 || footprint.activeBytes > 0 || reviewItems.isEmpty == false {
            items.append(.separator)
            items.append(.section(title: "Cleanup Readiness"))
            items.append(.safety(footprint: footprint, safeItemCount: safeItemCount))
        }

        let sortedReviewItems = reviewItems.sorted { lhs, rhs in
            if lhs.bytes == rhs.bytes {
                return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
            }
            return lhs.bytes > rhs.bytes
        }
        if sortedReviewItems.isEmpty == false {
            items.append(.reviewItems(
                items: sortedReviewItems,
                totalBytes: sortedReviewItems.reduce(0) { $0 + max(0, $1.bytes) }))
        }

        let visibleCleanupSuggestions = (allowsMenuCleanup ? cleanupSuggestions : [])
            .sorted { lhs, rhs in
                if lhs.bytes == rhs.bytes {
                    return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
                }
                return lhs.bytes > rhs.bytes
            }
            .prefix(3)

        if visibleCleanupSuggestions.isEmpty == false {
            items.append(.separator)
            items.append(.section(title: "Suggested Cleanup"))
            items.append(.cleanupSuggestions(
                suggestions: Array(visibleCleanupSuggestions),
                totalCount: safeItemCount,
                totalBytes: footprint.reclaimableBytes))
        }

        if footprint.unreadablePaths.isEmpty == false || footprint.missingPaths.isEmpty == false {
            items.append(.separator)
            items.append(.section(title: "Scan Notes"))
            items.append(.summary(
                title: "Skipped Paths",
                value: "\(footprint.unreadablePaths.count + footprint.missingPaths.count)",
                systemImage: "eye.slash"))
        }

        items.append(contentsOf: [
            .separator,
            .section(title: "Actions"),
            .command(title: "Open Dashboard", command: .openDashboard, keyEquivalent: "", isEnabled: true),
            .command(title: "Scan Now", command: .scanNow, keyEquivalent: "r", isEnabled: isScanning == false),
            .command(
                title: "Clean Safe Items...",
                command: .cleanSafe,
                keyEquivalent: "",
                isEnabled: allowsMenuCleanup && footprint.reclaimableBytes > 0),
            .separator,
            .command(title: "Settings...", command: .openSettings, keyEquivalent: ",", isEnabled: true),
        ])

        if showsUpdateCheck {
            items.append(.command(
                title: "Check for Updates...",
                command: .checkForUpdates,
                keyEquivalent: "",
                isEnabled: canCheckForUpdates))
        }

        items.append(.command(title: "Quit DELTREE", command: .quit, keyEquivalent: "q", isEnabled: true))

        return StatusMenuDescriptor(title: title, isWarning: footprint.hasLowDiskSpace, items: items)
    }
}
