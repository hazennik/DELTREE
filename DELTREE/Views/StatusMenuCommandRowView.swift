import SwiftUI

struct StatusMenuCommandRowView: View {
    @Environment(\.appTheme) private var theme
    @State private var isHovered = false

    var title: String
    var systemImage: String
    var keyEquivalent: String
    var isEnabled: Bool
    var action: () -> Void

    var body: some View {
        Button {
            guard isEnabled else { return }
            action()
        } label: {
            HStack(spacing: 8) {
                Text(theme.classicGlyph(for: systemImage))
                    .foregroundStyle(isEnabled ? theme.secondaryText : theme.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                    .frame(width: 48, alignment: .leading)

                Text("[\(title.uppercased())]")
                    .foregroundStyle(isEnabled ? theme.selectionText : theme.mutedText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)

                Spacer(minLength: 8)

                if keyEquivalent.isEmpty == false {
                    Text("CMD-\(keyEquivalent.uppercased())")
                        .foregroundStyle(isEnabled ? theme.secondaryText : theme.mutedText)
                        .lineLimit(1)
                }
            }
            .font(theme.font(.body))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(rowBackground)
            .overlay {
                if isHovered && isEnabled {
                    Rectangle()
                        .stroke(theme.panelBorder, lineWidth: 1)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(isEnabled == false)
        .onHover { hovering in
            isHovered = hovering
        }
        .accessibilityLabel(title)
        .accessibilityValue(isEnabled ? "Enabled" : "Disabled")
    }

    private var rowBackground: Color {
        guard isEnabled, isHovered else {
            return theme.background
        }
        return theme.selectionFill
    }
}

struct StatusMenuDividerView: View {
    @Environment(\.appTheme) private var theme

    var body: some View {
        Rectangle()
            .fill(theme.separator)
            .frame(height: 1)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .background(theme.background)
    }
}
