import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        ResizableSplitView(
            leadingMinWidth: 160,
            leadingIdealWidth: 240,
            trailingMinWidth: 460)
        {
            DomainSidebarView(
                summaries: viewModel.domainSummaries,
                totalBytes: viewModel.snapshot.totalBytes,
                selectedSection: $viewModel.selectedSection,
                selectedDomain: $viewModel.selectedDomain)
        } trailing: {
            DashboardDetailContentView(viewModel: viewModel)
                .frame(minWidth: 460, idealWidth: 880)
        }
        .frame(minWidth: 640, idealWidth: 1120, minHeight: 440, idealHeight: 720)
        .sheet(item: $viewModel.pendingCleanupPlan) { plan in
            CleanupPreflightView(
                plan: plan,
                confirmAction: { viewModel.performCleanup(plan) },
                cancelAction: { viewModel.pendingCleanupPlan = nil },
                exportAction: { viewModel.exportCleanupReport(plan: plan) })
        }
        .alert("Cleanup", isPresented: cleanupMessageBinding) {
            Button("OK") {
                viewModel.cleanupMessage = nil
            }
        } message: {
            Text(viewModel.cleanupMessage ?? "")
        }
    }

    private var cleanupMessageBinding: Binding<Bool> {
        Binding(
            get: { viewModel.cleanupMessage != nil },
            set: { if $0 == false { viewModel.cleanupMessage = nil } })
    }

}

#Preview {
    DashboardView(viewModel: .preview)
}
