import AppKit

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let automaticTerminationReason = "DELTREE menu bar agent"

    private var container: AppContainer?
    private var statusItemController: StatusItemController?
    private var dashboardWindowController: DashboardWindowController?
    private var settingsWindowController: SettingsWindowController?
    private var didDisableAutomaticTermination = false

    func configure(_ container: AppContainer) {
        self.container = container
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        guard let container else {
            return
        }
        guard Self.isRunningUnitTests == false else {
            return
        }

        ProcessInfo.processInfo.disableAutomaticTermination(Self.automaticTerminationReason)
        didDisableAutomaticTermination = true
        container.mainThreadHangWatchdog.start()
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
        container?.mainThreadHangWatchdog.stop()
        if didDisableAutomaticTermination {
            ProcessInfo.processInfo.enableAutomaticTermination(Self.automaticTerminationReason)
        }
    }

    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }
}
