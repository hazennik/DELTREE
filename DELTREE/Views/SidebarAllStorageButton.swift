import SwiftUI

struct SidebarAllStorageButton: View {
    @Environment(\.appTheme) private var theme

    var totalBytes: Int64
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            SidebarAllStorageRow(totalBytes: totalBytes)
        }
        .buttonStyle(.plain)
        .foregroundStyle(theme.primaryText)
    }
}
