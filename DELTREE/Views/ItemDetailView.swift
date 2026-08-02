import SwiftUI

struct ItemDetailView: View {
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
                            .font(.title3)
                            .fontWeight(.semibold)

                        DetailGridView(item: item)

                        Divider()

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Why It Exists")
                                .font(.headline)
                            Text(item.explanation)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Path")
                                .font(.headline)
                            Text(item.path)
                                .font(.system(.caption, design: .monospaced))
                                .textSelection(.enabled)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        if item.metadata.isEmpty == false {
                            MetadataListView(metadata: item.metadata)
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Actions")
                                .font(.headline)
                            Text(item.cleanupImpact)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            HStack {
                                if item.suggestedAction.isCleanupExecutionAction {
                                    Button(item.suggestedAction.displayName, systemImage: item.suggestedAction.systemImage) {
                                        cleanupAction(item, item.suggestedAction)
                                    }
                                    .disabled(item.isActive || item.isPinned || item.isIgnored)
                                }

                                if item.kind == .simulatorDevice, item.metadata["udid"] != nil {
                                    Button("Erase", systemImage: StorageAction.eraseSimulator.systemImage) {
                                        cleanupAction(item, .eraseSimulator)
                                    }
                                    .disabled(item.isActive)
                                }
                            }
                        }

                        HStack {
                            Button("Reveal", systemImage: "folder", action: { revealAction(item) })
                            Button("Copy Path", systemImage: "doc.on.doc", action: { copyPathAction(item) })
                        }

                        HStack {
                            Button("User-Owned", systemImage: StorageAction.markUserOwned.systemImage) {
                                markUserOwnedAction(item)
                            }
                            Button(item.isPinned ? "Unpin" : "Pin", systemImage: item.isPinned ? "pin.slash" : "pin") {
                                togglePinnedAction(item)
                            }
                            Button(item.isIgnored ? "Unignore" : "Ignore", systemImage: item.isIgnored ? "eye" : "eye.slash") {
                                toggleIgnoredAction(item)
                            }
                            Button("Reset", systemImage: StorageAction.resetAttribution.systemImage) {
                                resetAttributionAction(item)
                            }
                        }
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                ContentUnavailableView("No Item Selected", systemImage: "externaldrive", description: Text("Select a storage item to inspect its safety, owner, and path."))
            }
        }
        .background(.background)
    }
}
