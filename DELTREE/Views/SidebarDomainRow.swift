import SwiftUI

struct SidebarDomainRow: View {
    @Environment(\.appTheme) private var theme

    var summary: DomainSummary

    var body: some View {
        Label {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(summary.domain.displayName)
                    Text("\(summary.itemCount) item(s)")
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.secondaryText)
                }
                Spacer()
                Text(StorageFormatters.byteCount(summary.bytes))
                    .foregroundStyle(theme.secondaryText)
                    .monospacedDigit()
            }
        } icon: {
            Image(systemName: summary.domain.symbolName)
                .foregroundStyle(summary.domain.menuTint(in: theme))
        }
        .font(theme.font(.body))
    }
}
