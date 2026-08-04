import Foundation
import OSLog
import Sparkle

@MainActor
final class SparkleAppUpdater: AppUpdating {
    private let logger = Logger(subsystem: "com.Infrallabs.DELTREE", category: "updates")
    private let updaterController: SPUStandardUpdaterController
    private var didStart = false

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: false,
            updaterDelegate: nil,
            userDriverDelegate: nil)
    }

    var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
    }

    func start() {
        guard didStart == false else {
            return
        }

        updaterController.startUpdater()
        didStart = true
        logger.debug("Sparkle updater started.")
    }

    func checkForUpdates() {
        updaterController.updater.checkForUpdates()
    }

    func observeCanCheckForUpdates(_ handler: @escaping @MainActor (Bool) -> Void) -> AnyObject? {
        updaterController.updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { updater, _ in
            Task { @MainActor in
                handler(updater.canCheckForUpdates)
            }
        }
    }
}
