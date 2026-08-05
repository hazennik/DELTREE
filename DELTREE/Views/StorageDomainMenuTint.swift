import SwiftUI

extension StorageDomain {
    var menuTint: Color {
        menuTint(in: .modern)
    }

    func menuTint(in theme: AppTheme) -> Color {
        theme.domainTint(self)
    }
}
