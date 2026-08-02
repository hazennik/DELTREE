import SwiftUI

struct SidebarAllStorageRow: View {
    var totalBytes: Int64

    var body: some View {
        HStack {
            Label("All Storage", systemImage: "externaldrive")
            Spacer()
            Text(StorageFormatters.byteCount(totalBytes))
                .foregroundStyle(.secondary)
                .monospacedDigit()
        }
    }
}
