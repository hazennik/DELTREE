import SwiftUI

struct StatusMenuSummaryRowView: View {
    var title: String
    var value: String
    var systemImage: String?

    var body: some View {
        HStack(spacing: 8) {
            if let systemImage {
                Image(systemName: systemImage)
                    .foregroundStyle(.secondary)
                    .frame(width: 18)
            }

            Text(title)
                .lineLimit(1)

            Spacer(minLength: 8)

            Text(value)
                .monospacedDigit()
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }
}
