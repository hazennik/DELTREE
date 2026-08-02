import Foundation

enum StatusItemIconBadge: Hashable, Sendable {
    case none
    case reclaimable
    case warning
}

struct StatusItemIconState: Hashable, Sendable {
    var isFilled: Bool
    var badge: StatusItemIconBadge

    static func make(
        footprint: StorageFootprint,
        lastDelta: StorageDelta,
        isScanning: Bool) -> StatusItemIconState
    {
        let hasWarning = footprint.hasLowDiskSpace || footprint.unreadablePaths.isEmpty == false
        let hasReclaimableWork = footprint.reclaimableBytes > 0 || lastDelta.growthBytes > 0

        return StatusItemIconState(
            isFilled: isScanning,
            badge: hasWarning ? .warning : (hasReclaimableWork ? .reclaimable : .none))
    }

    var accessibilityDescription: String {
        switch (isFilled, badge) {
        case (true, .warning):
            "DELTREE scanning, attention needed"
        case (true, .reclaimable):
            "DELTREE scanning, reclaimable storage found"
        case (true, .none):
            "DELTREE scanning"
        case (false, .warning):
            "DELTREE attention needed"
        case (false, .reclaimable):
            "DELTREE reclaimable storage found"
        case (false, .none):
            "DELTREE idle"
        }
    }
}
