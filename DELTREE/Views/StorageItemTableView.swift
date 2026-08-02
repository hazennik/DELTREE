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
            .width(min: 120, ideal: 360)

            TableColumn("Size") { item in
                Text(StorageFormatters.byteCount(item.bytes))
                    .monospacedDigit()
            }
            .width(min: 64, ideal: 90)

            TableColumn("Safety") { item in
                VStack(alignment: .leading, spacing: 2) {
                    SafetyBadgeView(safety: item.safety, isActive: item.isActive)
                    Label(item.suggestedAction.displayName, systemImage: item.suggestedAction.systemImage)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            .width(min: 104, ideal: 160)
        }
    }
}
