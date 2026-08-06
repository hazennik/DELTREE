import SwiftUI

struct StatusMenuSectionHeaderView: View {
    @Environment(\.appTheme) private var theme

    var title: String

    var body: some View {
        Text(theme.isClassic ? "[ \(title.uppercased()) ]" : title.uppercased())
            .font(theme.font(.caption))
            .bold()
            .foregroundStyle(theme.isClassic ? theme.accent : theme.secondaryText)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 2)
            .background(theme.background)
    }
}
