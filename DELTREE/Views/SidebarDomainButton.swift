import SwiftUI

struct SidebarDomainButton: View {
    @Environment(\.appTheme) private var theme

    var summary: DomainSummary
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            SidebarDomainRow(summary: summary)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? theme.accent : theme.primaryText)
    }
}
