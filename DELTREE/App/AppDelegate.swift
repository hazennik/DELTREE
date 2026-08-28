import AppKit
import Darwin

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

        let environment = ProcessInfo.processInfo.environment
        if let screenshotDirectoryPath = environment["DELTREE_SCREENSHOT_OUTPUT_DIR"],
           screenshotDirectoryPath.isEmpty == false
        {
            Task { @MainActor in
                do {
                    try ScreenshotExportService.export(
                        to: URL(fileURLWithPath: screenshotDirectoryPath, isDirectory: true))
                    NSApp.terminate(nil)
                } catch {
                    fputs("DELTREE screenshot export failed: \(error.localizedDescription)\n", stderr)
                    exit(1)
                }
            }
            return
        }

        ProcessInfo.processInfo.disableAutomaticTermination(Self.automaticTerminationReason)
        didDisableAutomaticTermination = true
        container.mainThreadHangWatchdog.start()
        container.memoryPressureMonitor.start()
        let dashboardWindowController = DashboardWindowController(viewModel: container.dashboardViewModel)
        let settingsWindowController = SettingsWindowController(container: container)
        self.dashboardWindowController = dashboardWindowController
        self.settingsWindowController = settingsWindowController
        statusItemController = StatusItemController(
            viewModel: container.dashboardViewModel,
            settings: container.settings,
            openDashboard: { dashboardWindowController.show() },
            openSettings: { settingsWindowController.show() })
        if let startupWarning = container.startupWarning {
            presentStartupWarning(startupWarning)
        }
        if environment["DELTREE_DISABLE_INITIAL_SCAN"] != "1" {
            container.dashboardViewModel.start()
        }
        if environment["DELTREE_EXIT_AFTER_LAUNCH"] == "1" {
            DispatchQueue.main.async {
                NSApp.terminate(nil)
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        container?.dashboardViewModel.stop()
        container?.mainThreadHangWatchdog.stop()
        container?.memoryPressureMonitor.stop()
        if didDisableAutomaticTermination {
            ProcessInfo.processInfo.enableAutomaticTermination(Self.automaticTerminationReason)
        }
    }

    private static var isRunningUnitTests: Bool {
        ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
    }

    private func presentStartupWarning(_ message: String) {
        NSApp.activate(ignoringOtherApps: true)
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.messageText = "DELTREE history is not being saved"
        alert.informativeText = message
        alert.addButton(withTitle: "Continue")
        alert.runModal()
    }
}
