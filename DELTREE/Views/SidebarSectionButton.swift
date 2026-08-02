import SwiftUI

struct SidebarSectionButton: View {
    var section: DashboardSection
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            SidebarSectionRow(section: section)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
    }
}
