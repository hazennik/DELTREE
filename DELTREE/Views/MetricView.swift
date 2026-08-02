import SwiftUI

struct MetricView: View {
    var title: String
    var value: String
    var symbolName: String
    var tint: Color = .secondary

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: symbolName)
                .foregroundStyle(tint)
                .frame(width: 20)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.headline)
                    .monospacedDigit()
                    .lineLimit(1)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(.quaternary, in: RoundedRectangle(cornerRadius: 8))
    }
}
