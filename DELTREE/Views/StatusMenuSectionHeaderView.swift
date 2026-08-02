import SwiftUI

struct StatusMenuSectionHeaderView: View {
    var title: String

    var body: some View {
        Text(title.uppercased())
            .font(.caption)
            .bold()
            .foregroundStyle(.secondary)
            .tracking(0.8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.top, 4)
            .padding(.bottom, 2)
    }
}
