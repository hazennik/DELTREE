import SwiftUI

struct MetricView: View {
    @Environment(\.appTheme) private var theme

    var title: String
    var value: String
    var symbolName: String
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 8) {
            if theme.isClassic {
                Text(theme.classicGlyph(for: symbolName))
                    .font(theme.font(.caption))
                    .foregroundStyle(tint)
                    .frame(width: 36, alignment: .leading)
            } else {
                Image(systemName: symbolName)
                    .foregroundStyle(tint)
                    .frame(width: 20)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(theme.isClassic ? title.uppercased() : title)
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.secondaryText)
                Text(value)
                    .font(theme.font(.headline))
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
        .foregroundStyle(theme.primaryText)
        .appPanel(padding: 8)
    }
}
