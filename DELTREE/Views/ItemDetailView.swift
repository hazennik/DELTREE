import SwiftUI

struct ItemDetailView: View {
    @Environment(\.appTheme) private var theme

    var item: StorageItem?
    var revealAction: (StorageItem) -> Void
    var copyPathAction: (StorageItem) -> Void
    var cleanupAction: (StorageItem, StorageAction) -> Void
    var markUserOwnedAction: (StorageItem) -> Void
    var togglePinnedAction: (StorageItem) -> Void
    var toggleIgnoredAction: (StorageItem) -> Void
    var resetAttributionAction: (StorageItem) -> Void

    var body: some View {
        Group {
            if let item {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Label(item.displayName, systemImage: item.domain.symbolName)
                            .font(theme.font(.title3))
                            .bold()
                            .lineLimit(2)

                        ItemActionPanelView(
                            item: item,
                            revealAction: revealAction,
                            copyPathAction: copyPathAction,
                            cleanupAction: cleanupAction,
                            markUserOwnedAction: markUserOwnedAction,
                            togglePinnedAction: togglePinnedAction,
                            toggleIgnoredAction: toggleIgnoredAction,
                            resetAttributionAction: resetAttributionAction)

                        DetailGridView(item: item)

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Why It Exists")
                                .font(theme.font(.headline))
                            Text(item.explanation)
                                .foregroundStyle(theme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Path")
                                .font(theme.font(.headline))
                            Text(item.path)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .foregroundStyle(theme.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if item.metadata.isEmpty == false {
                            MetadataListView(metadata: item.metadata)
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ContentUnavailableView("No Item Selected", systemImage: "externaldrive", description: Text("Select a storage item to inspect its safety, owner, and path."))
            }
        }
        .background(theme.background)
        .foregroundStyle(theme.primaryText)
    }
}
