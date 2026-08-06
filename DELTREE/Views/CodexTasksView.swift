import SwiftUI

struct CodexTasksView<Detail: View>: View {
    @Environment(\.appTheme) private var theme

    var items: [StorageItem]
    @Binding var selectedItemID: StorageItem.ID?
    @Binding var sortOrder: [KeyPathComparator<StorageItem>]
    var itemDetail: Detail

    var body: some View {
        ResizableSplitView(
            leadingMinWidth: 240,
            leadingIdealWidth: 640,
            trailingMinWidth: 200)
        {
            VStack(spacing: 0) {
                Group {
                    if theme.isClassic {
                        classicTaskSummaryList
                    } else {
                        List(taskSummaries) { summary in
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Label(summary.title, systemImage: "terminal")
                                    Spacer()
                                    Text(StorageFormatters.byteCount(summary.bytes))
                                        .monospacedDigit()
                                }
                                Text("\(summary.itemCount) item(s)")
                                    .font(theme.font(.caption))
                                    .foregroundStyle(theme.secondaryText)
                            }
                        }
                        .scrollContentBackground(.hidden)
                    }
                }
                .background(theme.background)
                .foregroundStyle(theme.primaryText)
                .frame(minHeight: 120, idealHeight: 180)

                Divider()

                StorageItemTableView(
                    items: items,
                    selectedItemID: $selectedItemID,
                    sortOrder: $sortOrder)
            }
            .background(theme.background)
            .frame(minWidth: 240, idealWidth: 640)
        } trailing: {
            itemDetail
        }
    }

    private var classicTaskSummaryList: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                Text("[ CODEX TASKS ]")
                    .font(theme.font(.caption))
                    .foregroundStyle(theme.accent)

                if taskSummaries.isEmpty {
                    Text("NO CODEX TASK STORAGE FOUND.")
                        .font(theme.font(.caption))
                        .foregroundStyle(theme.secondaryText)
                } else {
                    ForEach(taskSummaries) { summary in
                        HStack {
                            Text(theme.classicGlyph(for: "terminal"))
                                .foregroundStyle(theme.safe)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(summary.title.uppercased())
                                Text("\(summary.itemCount) ITEM(S)")
                                    .font(theme.font(.caption))
                                    .foregroundStyle(theme.secondaryText)
                            }
                            Spacer()
                            Text(StorageFormatters.byteCount(summary.bytes))
                                .monospacedDigit()
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 5)
                        .background(theme.panelFill)
                        .overlay {
                            Rectangle()
                                .stroke(theme.panelBorder, lineWidth: 1)
                        }
                    }
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, alignment: .leading)
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
