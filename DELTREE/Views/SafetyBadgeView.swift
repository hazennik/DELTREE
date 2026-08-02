import SwiftUI

struct SafetyBadgeView: View {
    var safety: SafetyClassification
    var isActive: Bool

    var body: some View {
        Label(title, systemImage: symbolName)
            .font(.caption)
            .foregroundStyle(color)
            .lineLimit(1)
    }

    private var title: String {
        isActive ? "Active" : safety.displayName
    }

    private var symbolName: String {
        if isActive {
            return "play.circle"
        }
        switch safety {
        case .safeToTrash:
            return "checkmark.circle"
        case .probablySafe:
            return "checkmark.circle.trianglebadge.exclamationmark"
        case .reviewRecommended:
            return "exclamationmark.triangle"
        case .keep:
            return "lock"
        case .unknown:
            return "questionmark.circle"
        }
    }

    private var color: Color {
        if isActive {
            return .blue
        }
        switch safety {
        case .safeToTrash:
            return .green
        case .probablySafe:
            return .yellow
        case .reviewRecommended:
            return .orange
        case .keep:
            return .secondary
        case .unknown:
            return .secondary
        }
    }
}
