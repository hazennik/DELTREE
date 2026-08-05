import SwiftUI

struct SidebarSectionRow: View {
    @Environment(\.appTheme) private var theme

    var section: DashboardSection

    var body: some View {
        Group {
            if theme.isClassic {
                HStack(spacing: 8) {
                    Text(theme.classicGlyph(for: section.symbolName))
                        .foregroundStyle(theme.secondaryText)
                    Text(section.displayName.uppercased())
                }
            } else {
                Label(section.displayName, systemImage: section.symbolName)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
