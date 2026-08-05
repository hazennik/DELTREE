import SwiftUI

struct SidebarSectionButton: View {
    @Environment(\.appTheme) private var theme

    var section: DashboardSection
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            SidebarSectionRow(section: section)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? theme.accent : theme.primaryText)
    }
}
