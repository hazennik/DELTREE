import SwiftUI

struct StatusMenuSectionHeaderView: View {
    @Environment(\.appTheme) private var theme

    var title: String

    var body: some View {
        Text(theme.isClassic ? "[ \(title.uppercased()) ]" : title.uppercased())
            .font(theme.font(.caption))
            .bold()
            .foregroundStyle(theme.secondaryText)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 2)
    }
}
