import SwiftUI

struct SidebarAllStorageRow: View {
    @Environment(\.appTheme) private var theme

    var totalBytes: Int64

    var body: some View {
        HStack {
            Label("All Storage", systemImage: "externaldrive")
            Spacer()
            Text(StorageFormatters.byteCount(totalBytes))
                .foregroundStyle(theme.secondaryText)
                .monospacedDigit()
        }
        .font(theme.font(.body))
    }
}
