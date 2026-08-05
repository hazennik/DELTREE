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
        isClassic ? Color(red: 0.000, green: 0.004, blue: 0.016) : Color(NSColor.windowBackgroundColor)
    }

    var sidebarBackground: Color {
        isClassic ? Color(red: 0.000, green: 0.004, blue: 0.016) : Color(NSColor.controlBackgroundColor)
    }

    var panelFill: Color {
        isClassic ? Color(red: 0.000, green: 0.016, blue: 0.090) : Color.secondary.opacity(0.10)
    }

    var panelBorder: Color {
        isClassic ? Color(red: 0.000, green: 0.440, blue: 0.460) : Color.clear
    }

    var separator: Color {
        isClassic ? Color(red: 0.280, green: 0.300, blue: 0.320) : Color.secondary.opacity(0.24)
    }

    var primaryText: Color {
        isClassic ? Color(red: 0.720, green: 0.720, blue: 0.720) : .primary
    }

    var secondaryText: Color {
        isClassic ? Color(red: 0.520, green: 0.520, blue: 0.520) : .secondary
    }

    var mutedText: Color {
        isClassic ? Color(red: 0.360, green: 0.360, blue: 0.360) : .secondary
    }

    var accent: Color {
        isClassic ? Color(red: 0.000, green: 0.540, blue: 0.560) : Color.accentColor
    }

    var warning: Color {
        isClassic ? Color(red: 0.580, green: 0.360, blue: 0.140) : AppPalette.xcode
    }

    var danger: Color {
        isClassic ? Color(red: 0.580, green: 0.120, blue: 0.120) : .red
    }

    var safe: Color {
        isClassic ? normalTint : AppPalette.codex
    }

    var review: Color {
        isClassic ? warning : AppPalette.caution
    }

    var keep: Color {
        isClassic ? normalTint : .secondary
    }

    var unknown: Color {
        isClassic ? normalTint : .secondary
    }

    var controlFill: Color {
        isClassic ? Color(red: 0.000, green: 0.000, blue: 0.000) : Color(NSColor.controlBackgroundColor)
    }

    var selectionFill: Color {
        isClassic ? Color(red: 0.000, green: 0.180, blue: 0.260) : Color.accentColor.opacity(0.18)
    }

    var selectionText: Color {
        isClassic ? Color(red: 0.780, green: 0.780, blue: 0.780) : .primary
    }

    var normalTint: Color {
        isClassic ? secondaryText : .secondary
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
        guard isClassic == false else {
            return normalTint
        }

        switch domain {
        case .codexHome, .codexWorkspaces:
            return AppPalette.codex
        case .coreSimulatorDevices, .xcTestDevices:
            return AppPalette.simulator
        case .derivedData, .xcodeProducts, .swiftPackageCaches, .coreSimulatorCaches:
            return AppPalette.xcode
        case .xcResults:
            return AppPalette.results
        case .deviceSupport, .simulatorRuntimes, .simulatorImages:
            return AppPalette.device
        case .archives:
            return AppPalette.archive
        }
    }

    func safetyTint(_ safety: SafetyClassification, isActive: Bool) -> Color {
        if isActive {
            return isClassic ? normalTint : accent
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

    func classicGlyph(for systemImage: String) -> String {
        switch systemImage {
        case "archivebox", "externaldrive", "internaldrive":
            return "[DSK]"
        case "chart.pie":
            return "[SUM]"
        case "rectangle.grid.2x2":
            return "[WIN]"
        case "hammer":
            return "[BLD]"
        case "iphone":
            return "[DEV]"
        case "shippingbox":
            return "[ARC]"
        case "checklist":
            return "[TST]"
        case "square.stack.3d.up", "externaldrive.badge.icloud":
            return "[SYS]"
        case "clock.arrow.circlepath":
            return "[HST]"
        case "slider.horizontal.3":
            return "[CFG]"
        case "terminal":
            return "[CMD]"
        case "trash":
            return "[DEL]"
        case "arrow.clockwise":
            return "[RUN]"
        case "gearshape":
            return "[CFG]"
        case "power":
            return "[OFF]"
        case "magnifyingglass":
            return "[CHK]"
        case "iphone.slash":
            return "[DEL]"
        case "eraser":
            return "[ERS]"
        case "folder":
            return "[DIR]"
        case "doc.on.doc":
            return "[CPY]"
        case "square.and.arrow.down":
            return "[EXP]"
        case "eye.slash", "eye":
            return "[IGN]"
        case "person.crop.circle.badge.checkmark":
            return "[OWN]"
        case "arrow.uturn.backward":
            return "[RST]"
        case "link":
            return "[LNK]"
        case "plus.circle":
            return "[+]"
        case "clock":
            return "[CLK]"
        case "leaf.fill":
            return "[DT]"
        case "list.bullet.rectangle":
            return "[LST]"
        case "checkmark.shield":
            return "[OK]"
        case "exclamationmark.triangle":
            return "[REV]"
        case "lock":
            return "[LOCK]"
        case "questionmark.circle":
            return "[?]"
        default:
            return "[*]"
        }
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
            .font(theme.font(.body))
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
