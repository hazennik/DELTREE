import AppKit
import SwiftUI
import SwiftData

@main
struct DELTREEApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var container: AppContainer

    init() {
        let modelContainer = Self.makeModelContainer()
        let appContainer = AppContainer(modelContainer: modelContainer)
        _container = State(wrappedValue: appContainer)
        appDelegate.configure(appContainer)
    }

    var body: some Scene {
        Settings {
            SettingsView(
                settings: container.settings,
                viewModel: container.dashboardViewModel)
                .frame(width: 520, height: 420)
        }
        .modelContainer(container.modelContainer)
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            ScanHistoryRecord.self,
            CleanupHistoryRecord.self,
            AttributionEventRecord.self,
            StorageDeltaRecord.self,
            ManualOverrideRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
}
