import SwiftUI

struct DashboardDetailContentView: View {
    @Environment(\.appTheme) private var theme

    var viewModel: DashboardViewModel

    var body: some View {
        @Bindable var viewModel = viewModel

        switch viewModel.selectedSection {
        case .cleanupHistory:
            CleanupHistoryView(
                cleanupHistory: viewModel.cleanupHistory,
                deltaHistory: viewModel.deltaHistory)
        case .rules:
            RulesView(settings: viewModel.settings, viewModel: viewModel)
        default:
            VStack(spacing: 0) {
                StorageOverviewHeaderView(
                    snapshot: viewModel.snapshot,
                    footprint: viewModel.footprint,
                    lastDelta: viewModel.lastDelta,
                    isScanning: viewModel.isScanning,
                    scanAction: { viewModel.scan(force: true) },
                    cleanupAction: viewModel.prepareSafeCleanup)

                StorageBreakdownPanelView(footprint: viewModel.footprint)

                StorageFilterBarView(
                    searchText: $viewModel.searchText,
                    selectedSafety: $viewModel.selectedSafety,
                    selectedOwner: $viewModel.selectedOwner,
                    includeIgnoredItems: $viewModel.includeIgnoredItems)

                Divider()
                    .overlay(theme.separator)

                if viewModel.selectedSection == .codexTasks {
                    CodexTasksView(
                        items: viewModel.filteredItems,
                        selectedItemID: $viewModel.selectedItemID,
                        sortOrder: $viewModel.tableSortOrder,
                        itemDetail: itemDetail)
                } else {
                    ResizableSplitView(
                        leadingMinWidth: 240,
                        leadingIdealWidth: 640,
                        trailingMinWidth: 200)
                    {
                        StorageItemTableView(
                            items: viewModel.filteredItems,
                            selectedItemID: $viewModel.selectedItemID,
                            sortOrder: $viewModel.tableSortOrder)
                            .frame(minWidth: 240, idealWidth: 640)
                    } trailing: {
                        itemDetail
                    }
                }
            }
            .background(theme.background)
            .foregroundStyle(theme.primaryText)
        }
    }

    private var itemDetail: some View {
        ItemDetailView(
            item: viewModel.selectedItem,
            revealAction: viewModel.reveal,
            copyPathAction: viewModel.copyPath,
            cleanupAction: viewModel.prepareCleanup,
            markUserOwnedAction: viewModel.markUserOwned,
            togglePinnedAction: viewModel.togglePinned,
            toggleIgnoredAction: viewModel.toggleIgnored,
            resetAttributionAction: viewModel.resetAttribution)
            .frame(minWidth: 200, idealWidth: 240)
    }
}
