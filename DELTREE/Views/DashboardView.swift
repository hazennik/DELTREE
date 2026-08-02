import SwiftUI

struct DashboardView: View {
    @State private var viewModel: DashboardViewModel

    init(viewModel: DashboardViewModel) {
        _viewModel = State(wrappedValue: viewModel)
    }

    var body: some View {
        @Bindable var viewModel = viewModel

        HSplitView {
            DomainSidebarView(
                summaries: viewModel.domainSummaries,
                totalBytes: viewModel.snapshot.totalBytes,
                selectedSection: $viewModel.selectedSection,
                selectedDomain: $viewModel.selectedDomain)

            DashboardDetailContentView(viewModel: viewModel)
                .frame(minWidth: 0)
        }
        .frame(minWidth: 0, minHeight: 0)
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
