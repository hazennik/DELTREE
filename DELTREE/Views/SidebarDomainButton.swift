import SwiftUI

struct SidebarDomainButton: View {
    var summary: DomainSummary
    var isSelected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            SidebarDomainRow(summary: summary)
        }
        .buttonStyle(.plain)
        .foregroundStyle(isSelected ? Color.accentColor : Color.primary)
    }
}
