import SwiftUI

struct SidebarSectionRow: View {
    var section: DashboardSection

    var body: some View {
        Label(section.displayName, systemImage: section.symbolName)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
