import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var container: AppContainer?
    private var statusItemController: StatusItemController?
    private var dashboardWindowController: DashboardWindowController?

    func configure(_ container: AppContainer) {
        self.container = container
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let container else {
            return
        }

        let dashboardWindowController = DashboardWindowController(viewModel: container.dashboardViewModel)
        self.dashboardWindowController = dashboardWindowController
        statusItemController = StatusItemController(
            viewModel: container.dashboardViewModel,
            openDashboard: { dashboardWindowController.show() },
            openSettings: { Self.openSettingsWindow() })
        if ProcessInfo.processInfo.environment["DELTREE_DISABLE_INITIAL_SCAN"] != "1" {
            container.dashboardViewModel.start()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        container?.dashboardViewModel.stop()
    }

    private static func openSettingsWindow() {
        NSApp.activate(ignoringOtherApps: true)
        let selectors = [
            Selector(("showSettingsWindow:")),
            Selector(("showPreferencesWindow:")),
        ]

        for selector in selectors where NSApp.sendAction(selector, to: nil, from: nil) {
            return
        }
    }
}
