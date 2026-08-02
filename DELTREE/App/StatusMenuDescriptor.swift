import Foundation

enum StatusMenuCommand: String, Hashable, Sendable {
    case openDashboard
    case scanNow
    case cleanSafe
    case openSettings
    case quit
}

enum StatusMenuItemDescriptor: Hashable, Sendable {
    case summary(title: String, value: String, systemImage: String?)
    case breakdown(StorageFootprint)
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
        safeItemCount: Int) -> StatusMenuDescriptor
    {
        var items: [StatusMenuItemDescriptor] = [
            .summary(title: "Total", value: StorageFormatters.byteCount(footprint.totalBytes), systemImage: "externaldrive"),
            .summary(title: "Codex-related", value: StorageFormatters.byteCount(footprint.codexAttributedBytes), systemImage: "terminal"),
            .summary(title: "Xcode-related", value: StorageFormatters.byteCount(footprint.xcodeRelatedBytes), systemImage: "hammer"),
            .summary(title: "Reclaimable", value: StorageFormatters.byteCount(footprint.reclaimableBytes), systemImage: "trash"),
        ]

        if isScanning {
            items.append(.summary(title: "Status", value: "Scanning...", systemImage: "arrow.clockwise"))
        }

        if lastDelta.growthBytes > 0 {
            items.append(.summary(title: "Last Codex Run Impact", value: StorageFormatters.byteCount(lastDelta.codexImpactBytes), systemImage: "plus.circle"))
        }

        items.append(.breakdown(footprint))
        items.append(.separator)

        for breakdown in footprint.domainBreakdowns.prefix(5) {
            items.append(.summary(
                title: breakdown.domain.displayName,
                value: StorageFormatters.byteCount(breakdown.bytes),
                systemImage: breakdown.domain.symbolName))
        }

        let safeCount = footprint.topComponents.filter { $0.safety == .safeToTrash }.count
        let reviewCount = footprint.topComponents.filter { $0.safety == .probablySafe || $0.safety == .reviewRecommended }.count
        if safeCount > 0 || reviewCount > 0 || footprint.activeBytes > 0 {
            items.append(.separator)
            items.append(.summary(title: "Safe Items", value: "\(safeItemCount)", systemImage: "checkmark.circle"))
            items.append(.summary(title: "Needs Review", value: StorageFormatters.byteCount(footprint.reviewBytes), systemImage: "exclamationmark.triangle"))
            items.append(.summary(title: "Active / Kept", value: StorageFormatters.byteCount(footprint.activeBytes), systemImage: "lock"))
        }

        if footprint.unreadablePaths.isEmpty == false || footprint.missingPaths.isEmpty == false {
            items.append(.separator)
            items.append(.summary(
                title: "Skipped Paths",
                value: "\(footprint.unreadablePaths.count + footprint.missingPaths.count)",
                systemImage: "eye.slash"))
        }

        items.append(contentsOf: [
            .separator,
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
