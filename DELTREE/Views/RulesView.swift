import SwiftUI

struct RulesView: View {
    var settings: AppSettingsStore
    var viewModel: DashboardViewModel

    var body: some View {
        SettingsView(settings: settings, viewModel: viewModel)
            .navigationTitle("Rules")
    }
}
