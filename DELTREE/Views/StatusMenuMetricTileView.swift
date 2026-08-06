import SwiftUI

struct StatusMenuMetricTileView: View {
    @Environment(\.appTheme) private var theme

    var title: String
    var value: String
    var systemImage: String
    var tint: Color

    var body: some View {
        HStack(spacing: 8) {
            if theme.isClassic {
                Text(theme.classicGlyph(for: systemImage))
                    .font(theme.font(.caption))
                    .foregroundStyle(tint)
                    .frame(width: 36, alignment: .leading)
            } else {
                Image(systemName: systemImage)
                    .foregroundStyle(theme.markerTint(tint))
                    .frame(width: 18)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(theme.isClassic ? title.uppercased() : title)
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)

                Text(value)
                    .font(theme.font(.headline))
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .foregroundStyle(theme.primaryText)
        .appPanel(padding: 0)
    }
}
