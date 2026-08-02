import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let automaticTerminationReason = "DELTREE menu bar agent"

    private var container: AppContainer?
    private var statusItemController: StatusItemController?
    private var dashboardWindowController: DashboardWindowController?
    private var settingsWindowController: SettingsWindowController?

    func configure(_ container: AppContainer) {
        self.container = container
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let container else {
            return
        }

        ProcessInfo.processInfo.disableAutomaticTermination(Self.automaticTerminationReason)
        let dashboardWindowController = DashboardWindowController(viewModel: container.dashboardViewModel)
        let settingsWindowController = SettingsWindowController(container: container)
        self.dashboardWindowController = dashboardWindowController
        self.settingsWindowController = settingsWindowController
        statusItemController = StatusItemController(
            viewModel: container.dashboardViewModel,
            openDashboard: { dashboardWindowController.show() },
            openSettings: { settingsWindowController.show() })
        if ProcessInfo.processInfo.environment["DELTREE_DISABLE_INITIAL_SCAN"] != "1" {
            container.dashboardViewModel.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        container?.dashboardViewModel.stop()
        ProcessInfo.processInfo.enableAutomaticTermination(Self.automaticTerminationReason)
    }
}
