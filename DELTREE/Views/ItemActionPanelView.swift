import SwiftUI

struct ItemActionPanelView: View {
    @Environment(\.appTheme) private var theme

    var item: StorageItem
    var revealAction: (StorageItem) -> Void
    var copyPathAction: (StorageItem) -> Void
    var cleanupAction: (StorageItem, StorageAction) -> Void
    var markUserOwnedAction: (StorageItem) -> Void
    var togglePinnedAction: (StorageItem) -> Void
    var toggleIgnoredAction: (StorageItem) -> Void
    var resetAttributionAction: (StorageItem) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Actions")
                .font(theme.font(.headline))

            if item.cleanupImpact.isEmpty == false {
                Text(item.cleanupImpact)
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.secondaryText)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
                    .help(item.cleanupImpact)
            }

            VStack(alignment: .leading, spacing: 6) {
                if item.suggestedAction.isCleanupExecutionAction {
                    Button(primaryCleanupTitle(for: item.suggestedAction), systemImage: item.suggestedAction.systemImage) {
                        cleanupAction(item, item.suggestedAction)
                    }
                    .disabled(item.isActive || item.isPinned || item.isIgnored)
                    .help(item.suggestedAction.displayName)
                }

                if item.kind == .simulatorDevice, item.metadata["udid"] != nil {
                    Button("Erase", systemImage: StorageAction.eraseSimulator.systemImage) {
                        cleanupAction(item, .eraseSimulator)
                    }
                    .disabled(item.isActive)
                    .help(StorageAction.eraseSimulator.displayName)
                }
            }
            .buttonStyle(.bordered)
            .controlSize(.small)

            LazyVGrid(columns: buttonColumns, alignment: .leading, spacing: 6) {
                Button("Reveal", systemImage: "folder", action: { revealAction(item) })
                    .help("Reveal in Finder")
                Button("Copy", systemImage: "doc.on.doc", action: { copyPathAction(item) })
                    .help("Copy path")
                Button("Owner", systemImage: StorageAction.markUserOwned.systemImage) {
                    markUserOwnedAction(item)
                }
                .help(StorageAction.markUserOwned.displayName)
                Button(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin") {
                    togglePinnedAction(item)
                }
                Button(item.isIgnored ? "Show" : "Ignore", systemImage: item.isIgnored ? "eye" : "eye.slash") {
                    toggleIgnoredAction(item)
                }
                Button("Reset", systemImage: StorageAction.resetAttribution.systemImage) {
                    resetAttributionAction(item)
                }
                .help(StorageAction.resetAttribution.displayName)
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
        .appPanel(padding: 10)
    }

    private var buttonColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 78), spacing: 6)]
    }

    private func primaryCleanupTitle(for action: StorageAction) -> String {
        switch action {
        case .moveToTrash:
            "Trash"
        case .deleteUnavailableSimulator:
            "Delete"
        case .eraseSimulator:
            "Erase"
        case .cleanDerivedData:
            "Clean"
        case .removeXCResult, .removeCodexWorkspace:
            "Remove"
        case .none, .revealInFinder, .copyPath, .exportReport, .ignore, .markUserOwned, .resetAttribution:
            action.displayName
        }
    }
}
