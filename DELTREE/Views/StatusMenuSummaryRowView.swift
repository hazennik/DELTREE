import SwiftUI

struct StatusMenuSummaryRowView: View {
    @Environment(\.appTheme) private var theme

    var title: String
    var value: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(theme.secondaryText)
                    .frame(width: 18)
            }

            Text(title)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(value)
                .monospacedDigit()
                .foregroundStyle(theme.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(theme.font(.caption))
        .foregroundStyle(theme.primaryText)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}
