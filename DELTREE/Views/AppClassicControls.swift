import SwiftUI

struct ClassicButtonStyle: ButtonStyle {
    @Environment(\.appTheme) private var theme
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(theme.font(.body))
            .lineLimit(1)
            .minimumScaleFactor(0.82)
            .foregroundStyle(foregroundColor(isPressed: configuration.isPressed))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(backgroundColor(isPressed: configuration.isPressed))
            .overlay {
                Rectangle()
                    .stroke(isEnabled ? theme.panelBorder : theme.separator, lineWidth: 1)
            }
    }

    private func foregroundColor(isPressed: Bool) -> Color {
        guard isEnabled else { return theme.mutedText }
        return isPressed ? theme.background : theme.selectionText
    }

    private func backgroundColor(isPressed: Bool) -> Color {
        guard isEnabled else { return theme.controlFill.opacity(0.55) }
        return isPressed ? theme.accent : theme.controlFill
    }
}

struct ClassicToggleButton: View {
    @Environment(\.appTheme) private var theme

    var title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 6) {
                Text("[\(isOn ? "X" : " ")]")
                    .foregroundStyle(theme.selectionText)
                Text(title.uppercased())
            }
        }
        .buttonStyle(ClassicButtonStyle())
        .accessibilityLabel(title)
        .accessibilityValue(isOn ? "On" : "Off")
    }
}

struct ClassicOptionButton: View {
    @Environment(\.appTheme) private var theme

    var title: String
    var value: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Text(title.uppercased())
                    .foregroundStyle(theme.secondaryText)
                Text(value.uppercased())
                    .foregroundStyle(theme.selectionText)
            }
        }
        .buttonStyle(ClassicButtonStyle())
        .accessibilityLabel(title)
        .accessibilityValue(value)
    }
}

struct ClassicSection<Content: View>: View {
    @Environment(\.appTheme) private var theme

    var title: String
    @ViewBuilder var content: Content

    init(_ title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("[ \(title.uppercased()) ]")
                .font(theme.font(.headline))
                .foregroundStyle(theme.accent)

            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(theme.panelFill)
            .overlay {
                Rectangle()
                    .stroke(theme.panelBorder, lineWidth: 1)
            }
        }
    }
}

struct ClassicEmptyState: View {
    @Environment(\.appTheme) private var theme

    var title: String
    var message: String

    var body: some View {
        VStack(spacing: 8) {
            Text("+----------------------+")
                .foregroundStyle(theme.separator)
            Text(title.uppercased())
                .font(theme.font(.headline))
                .foregroundStyle(theme.selectionText)
            Text(message.uppercased())
                .font(theme.font(.caption))
                .foregroundStyle(theme.secondaryText)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
            Text("+----------------------+")
                .foregroundStyle(theme.separator)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(theme.background)
    }
}

private struct ClassicTextFieldModifier: ViewModifier {
    @Environment(\.appTheme) private var theme

    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(theme.font(.body))
            .foregroundStyle(theme.selectionText)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(theme.controlFill)
            .overlay {
                Rectangle()
                    .stroke(theme.panelBorder, lineWidth: 1)
            }
    }
}

extension View {
    func classicTextField() -> some View {
        modifier(ClassicTextFieldModifier())
    }
}
