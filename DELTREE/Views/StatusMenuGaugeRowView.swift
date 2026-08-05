import SwiftUI

struct StatusMenuGaugeRowView: View {
    @Environment(\.appTheme) private var theme

    var title: String
    var value: String
    var detail: String?
    var systemImage: String
    var tint: Color
    var share: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Label(title, systemImage: systemImage)
                    .lineLimit(1)

                Spacer(minLength: 8)

                Text(value)
                    .monospacedDigit()
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            if theme.isClassic {
                Text(theme.blockMeter(share: share, width: 14))
                    .foregroundStyle(tint)
                    .font(theme.font(.caption))
                    .monospaced()
            } else {
                GeometryReader { proxy in
                    RoundedRectangle(cornerRadius: 3)
                        .fill(theme.panelFill)
                        .overlay(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(tint)
                                .frame(width: fillWidth(for: proxy.size.width))
                        }
                        .clipped()
                }
                .frame(height: 6)
            }

            if let detail {
                Text(detail)
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(1)
            }
        }
        .font(theme.font(.caption))
        .foregroundStyle(theme.primaryText)
    }

    private var clampedShare: Double {
        min(1, max(0, share))
    }

    private func fillWidth(for availableWidth: CGFloat) -> CGFloat {
        guard availableWidth > 0, clampedShare > 0 else {
            return 0
        }

        return min(availableWidth, max(3, availableWidth * clampedShare))
    }
}
