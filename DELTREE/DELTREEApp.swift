import AppKit
import SwiftUI
import SwiftData

@main
struct DELTREEApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @State private var container: AppContainer

    init() {
        let modelContainerBootstrap = Self.makeModelContainer()
        let appContainer = AppContainer(
            modelContainer: modelContainerBootstrap.container,
            startupWarning: modelContainerBootstrap.warning)
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
        .commands {
            if container.updateService.isVisible {
                CommandGroup(after: .appInfo) {
                    Button("Check for Updates...") {
                        container.updateService.checkForUpdates()
                    }
                    .disabled(container.updateService.canCheckForUpdates == false)
                }
            }
        }
    }

    private struct ModelContainerBootstrap {
        var container: ModelContainer
        var warning: String?
    }

    private static func makeModelContainer() -> ModelContainerBootstrap {
        let schema = Schema([
            ScanHistoryRecord.self,
            CleanupHistoryRecord.self,
            AttributionEventRecord.self,
            StorageDeltaRecord.self,
            ManualOverrideRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            return ModelContainerBootstrap(container: container, warning: nil)
        } catch {
            let fallbackConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            if let fallback = try? ModelContainer(for: schema, configurations: [fallbackConfiguration]) {
                let warning = "DELTREE could not open its on-disk history database and is using temporary in-memory storage for this launch. Scan, attribution, cleanup history, and manual overrides will not persist. Underlying error: \(error.localizedDescription)"
                return ModelContainerBootstrap(container: fallback, warning: warning)
            }
            preconditionFailure("Could not create ModelContainer: \(error)")
        }
    }
}
