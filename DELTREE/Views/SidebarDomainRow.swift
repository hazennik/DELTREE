import SwiftUI

struct SidebarDomainRow: View {
    var summary: DomainSummary

    var body: some View {
        Label {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.domain.displayName)
                    Text("\(summary.itemCount) item(s)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Text(StorageFormatters.byteCount(summary.bytes))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        } icon: {
            Image(systemName: summary.domain.symbolName)
        }
    }
}
