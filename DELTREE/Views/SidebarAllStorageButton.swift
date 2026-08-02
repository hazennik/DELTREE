import SwiftUI

struct SidebarAllStorageButton: View {
    var totalBytes: Int64
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            SidebarAllStorageRow(totalBytes: totalBytes)
        }
        .buttonStyle(.plain)
    }
}
