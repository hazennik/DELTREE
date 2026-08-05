import SwiftUI

struct SafetyBadgeView: View {
    @Environment(\.appTheme) private var theme

    var safety: SafetyClassification
    var isActive: Bool

    var body: some View {
        Group {
            if theme.isClassic {
                Text(title)
            } else {
                Label(title, systemImage: symbolName)
            }
        }
        .font(theme.font(.caption))
        .foregroundStyle(color)
        .lineLimit(1)
        .accessibilityLabel(accessibilityTitle)
    }

    private var title: String {
        theme.safetyTitle(safety, isActive: isActive)
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
        theme.markerTint(theme.safetyTint(safety, isActive: isActive))
    }

    private var accessibilityTitle: String {
        isActive ? "Active" : safety.displayName
    }
}
