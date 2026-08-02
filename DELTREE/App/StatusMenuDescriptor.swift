import Foundation

enum StatusMenuCommand: String, Hashable, Sendable {
    case openDashboard
    case scanNow
    case cleanSafe
    case openSettings
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
        case .quit:
            "power"
        }
    }
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

        let safeCount = footprint.topComponents.filter { $0.safety == .safeToTrash }.count
        let reviewCount = footprint.topComponents.filter { $0.safety == .probablySafe || $0.safety == .reviewRecommended }.count
        if safeCount > 0 || reviewCount > 0 || footprint.activeBytes > 0 {
            items.append(.separator)
            items.append(.section(title: "Cleanup Readiness"))
            items.append(.safety(footprint: footprint, safeItemCount: safeItemCount))
        }

        let visibleCleanupSuggestions = cleanupSuggestions
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
            .command(title: "Clean Safe Items...", command: .cleanSafe, keyEquivalent: "", isEnabled: footprint.reclaimableBytes > 0),
            .separator,
            .command(title: "Settings...", command: .openSettings, keyEquivalent: ",", isEnabled: true),
            .command(title: "Quit DELTREE", command: .quit, keyEquivalent: "q", isEnabled: true),
        ])

        return StatusMenuDescriptor(title: title, isWarning: footprint.hasLowDiskSpace, items: items)
    }
}
