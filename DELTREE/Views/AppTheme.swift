import AppKit
import SwiftUI

struct AppTheme: Equatable {
    var mode: AppVisualMode

    static let classic = AppTheme(mode: .classic)
    static let modern = AppTheme(mode: .modern)

    var isClassic: Bool {
        mode == .classic
    }

    var background: Color {
        isClassic ? Color(red: 0.018, green: 0.020, blue: 0.022) : Color(NSColor.windowBackgroundColor)
    }

    var sidebarBackground: Color {
        isClassic ? Color(red: 0.012, green: 0.014, blue: 0.016) : Color(NSColor.controlBackgroundColor)
    }

    var panelFill: Color {
        isClassic ? Color(red: 0.055, green: 0.060, blue: 0.062) : Color.secondary.opacity(0.10)
    }

    var panelBorder: Color {
        isClassic ? Color(red: 0.00, green: 0.78, blue: 0.84).opacity(0.38) : Color.clear
    }

    var separator: Color {
        isClassic ? Color(red: 0.42, green: 0.48, blue: 0.48).opacity(0.42) : Color.secondary.opacity(0.24)
    }

    var primaryText: Color {
        isClassic ? Color(red: 0.88, green: 0.91, blue: 0.87) : .primary
    }

    var secondaryText: Color {
        isClassic ? Color(red: 0.63, green: 0.69, blue: 0.66) : .secondary
    }

    var mutedText: Color {
        isClassic ? Color(red: 0.43, green: 0.49, blue: 0.47) : .secondary
    }

    var accent: Color {
        isClassic ? Color(red: 0.00, green: 0.95, blue: 0.98) : Color.accentColor
    }

    var warning: Color {
        isClassic ? Color(red: 1.00, green: 0.72, blue: 0.22) : AppPalette.xcode
    }

    var danger: Color {
        isClassic ? Color(red: 1.00, green: 0.23, blue: 0.18) : .red
    }

    var safe: Color {
        isClassic ? Color(red: 0.39, green: 0.82, blue: 0.50) : AppPalette.codex
    }

    var review: Color {
        isClassic ? Color(red: 1.00, green: 0.72, blue: 0.22) : AppPalette.caution
    }

    var keep: Color {
        isClassic ? Color(red: 0.72, green: 0.78, blue: 0.74) : .secondary
    }

    var unknown: Color {
        isClassic ? Color(red: 0.00, green: 0.88, blue: 0.92) : .secondary
    }

    var panelCornerRadius: CGFloat {
        isClassic ? 0 : 8
    }

    var storageMeterHeight: CGFloat {
        isClassic ? 20 : 14
    }

    var colorScheme: ColorScheme? {
        isClassic ? .dark : nil
    }

    func font(_ style: Font.TextStyle) -> Font {
        .system(style, design: isClassic ? .monospaced : .default)
    }

    func domainTint(_ domain: StorageDomain) -> Color {
        switch domain {
        case .codexHome, .codexWorkspaces:
            isClassic ? Color(red: 0.55, green: 0.74, blue: 0.92) : AppPalette.codex
        case .coreSimulatorDevices, .xcTestDevices:
            isClassic ? accent : AppPalette.simulator
        case .derivedData, .xcodeProducts, .swiftPackageCaches, .coreSimulatorCaches:
            isClassic ? warning : AppPalette.xcode
        case .xcResults:
            isClassic ? Color(red: 0.92, green: 0.42, blue: 1.00) : AppPalette.results
        case .deviceSupport, .simulatorRuntimes, .simulatorImages:
            isClassic ? Color(red: 0.42, green: 0.72, blue: 1.00) : AppPalette.device
        case .archives:
            isClassic ? Color(red: 0.72, green: 0.78, blue: 0.74) : AppPalette.archive
        }
    }

    func safetyTint(_ safety: SafetyClassification, isActive: Bool) -> Color {
        if isActive {
            return accent
        }

        switch safety {
        case .safeToTrash:
            return safe
        case .probablySafe, .reviewRecommended:
            return review
        case .keep:
            return keep
        case .unknown:
            return unknown
        }
    }

    func safetyTitle(_ safety: SafetyClassification, isActive: Bool) -> String {
        guard isClassic else {
            return isActive ? "Active" : safety.displayName
        }

        if isActive {
            return "[ACTIVE]"
        }

        switch safety {
        case .safeToTrash:
            return "[SAFE]"
        case .probablySafe, .reviewRecommended:
            return "[REVIEW]"
        case .keep:
            return "[KEEP]"
        case .unknown:
            return "[UNKNOWN]"
        }
    }

    func blockMeter(share: Double, width: Int = 10) -> String {
        let clampedShare = min(1, max(0, share))
        let filledCount = Int((clampedShare * Double(width)).rounded())
        let emptyCount = max(0, width - filledCount)
        let percent = Int((clampedShare * 100).rounded())
        return "\(String(repeating: "█", count: filledCount))\(String(repeating: "░", count: emptyCount)) \(percent)%"
    }
}

private struct AppThemeKey: EnvironmentKey {
    static let defaultValue = AppTheme.classic
}

extension EnvironmentValues {
    var appTheme: AppTheme {
        get { self[AppThemeKey.self] }
        set { self[AppThemeKey.self] = newValue }
    }
}

extension View {
    func appTheme(_ theme: AppTheme) -> some View {
        environment(\.appTheme, theme)
            .tint(theme.accent)
            .preferredColorScheme(theme.colorScheme)
    }
}

struct AppPanelModifier: ViewModifier {
    @Environment(\.appTheme) private var theme
    var padding: CGFloat

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(theme.panelFill)
            .overlay {
                if theme.isClassic {
                    Rectangle()
                        .stroke(theme.panelBorder, lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: theme.panelCornerRadius))
    }
}

extension View {
    func appPanel(padding: CGFloat = 10) -> some View {
        modifier(AppPanelModifier(padding: padding))
    }
}
