import SwiftUI

struct CodexTasksView<Detail: View>: View {
    var items: [StorageItem]
    @Binding var selectedItemID: StorageItem.ID?
    @Binding var sortOrder: [KeyPathComparator<StorageItem>]
    var itemDetail: Detail

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                List(taskSummaries) { summary in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Label(summary.title, systemImage: "terminal")
                            Spacer()
                            Text(StorageFormatters.byteCount(summary.bytes))
                                .monospacedDigit()
                        }
                        Text("\(summary.itemCount) item(s)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(minHeight: 120, idealHeight: 180)

                Divider()

                StorageItemTableView(
                    items: items,
                    selectedItemID: $selectedItemID,
                    sortOrder: $sortOrder)
            }
            .frame(minWidth: 240)

            itemDetail
        }
    }

    private var taskSummaries: [CodexTaskSummary] {
        let grouped = Dictionary(grouping: items) { item in
            item.relatedCodexTask.isEmpty ? "Unmatched Codex Storage" : item.relatedCodexTask
        }
        return grouped.map { title, items in
            CodexTaskSummary(
                title: title,
                bytes: items.reduce(0) { $0 + max(0, $1.bytes) },
                itemCount: items.count)
        }
        .sorted { $0.bytes > $1.bytes }
    }
}

private struct CodexTaskSummary: Identifiable {
    var id: String { title }
    var title: String
    var bytes: Int64
    var itemCount: Int
}
