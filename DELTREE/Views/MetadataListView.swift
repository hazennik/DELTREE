import SwiftUI

struct MetadataListView: View {
    @Environment(\.appTheme) private var theme

    var metadata: [String: String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Metadata")
                .font(theme.font(.headline))
            ForEach(metadata.keys.sorted(), id: \.self) { key in
                HStack(alignment: .firstTextBaseline) {
                    Text(key)
                        .foregroundStyle(theme.secondaryText)
                        .frame(width: 110, alignment: .leading)
                    Text(metadata[key] ?? "")
                        .textSelection(.enabled)
                        .lineLimit(2)
                }
                .font(theme.font(.caption))
            }
        }
    }
}
