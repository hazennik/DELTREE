import SwiftUI

struct StorageItemTableView: View {
    var items: [StorageItem]
    @Binding var selectedItemID: StorageItem.ID?
    @Binding var sortOrder: [KeyPathComparator<StorageItem>]

    var body: some View {
        Table(items, selection: $selectedItemID, sortOrder: $sortOrder) {
            TableColumn("Name") { item in
                Label(item.displayName, systemImage: item.domain.symbolName)
                    .lineLimit(1)
                    .help(item.path)
            }
            .width(min: 180, ideal: 240)
            TableColumn("Domain") { item in
                Text(item.domain.displayName)
            }
            .width(min: 120, ideal: 150)
            TableColumn("Kind") { item in
                Text(item.kind.displayName)
            }
            .width(min: 110, ideal: 140)
            TableColumn("Size") { item in
                Text(StorageFormatters.byteCount(item.bytes))
                    .monospacedDigit()
            }
            .width(min: 80, ideal: 100)
            TableColumn("Last Used") { item in
                Text(StorageFormatters.ageString(from: item.lastActivityAt))
                    .monospacedDigit()
            }
            .width(min: 90, ideal: 110)
            TableColumn("Owner") { item in
                Text(item.attribution.displayName)
            }
            .width(min: 110, ideal: 130)
            TableColumn("Project") { item in
                Text(item.relatedProject.isEmpty ? "-" : item.relatedProject)
                    .lineLimit(1)
            }
            .width(min: 110, ideal: 150)
            TableColumn("Codex Task") { item in
                Text(item.relatedCodexTask.isEmpty ? "-" : item.relatedCodexTask)
                    .lineLimit(1)
            }
            .width(min: 130, ideal: 180)
            TableColumn("State") { item in
                Text(stateText(for: item))
                    .lineLimit(1)
            }
            .width(min: 130, ideal: 170)
            TableColumn("Safety") { item in
                VStack(alignment: .leading, spacing: 2) {
                    SafetyBadgeView(safety: item.safety, isActive: item.isActive)
                    Label(item.suggestedAction.displayName, systemImage: item.suggestedAction.systemImage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .width(min: 150, ideal: 180)
        }
    }

    private func stateText(for item: StorageItem) -> String {
        let state = item.stateDescription
        let runtime = item.runtimeOrDevice

        if state.isEmpty {
            return runtime.isEmpty ? "-" : runtime
        }
        if runtime.isEmpty {
            return state
        }
        return "\(state) - \(runtime)"
    }
}
