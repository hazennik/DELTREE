import Foundation
import OSLog
import Sparkle

@MainActor
final class SparkleAppUpdater: NSObject, AppUpdating, SPUUpdaterDelegate {
    private final class ImmediateInstallHandler: @unchecked Sendable {
        private let handler: () -> Void

        init(_ handler: @escaping () -> Void) {
            self.handler = handler
        }

        func install() {
            handler()
        }
    }

    private let logger = Logger(subsystem: "com.Infrallabs.DELTREE", category: "updates")
    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: false,
        updaterDelegate: self,
        userDriverDelegate: nil)
    private var didStart = false
    private var immediateInstallHandler: ImmediateInstallHandler?
    private var updateReadyHandler: (@MainActor (Bool) -> Void)?
    private(set) var isUpdateReady = false {
        didSet { updateReadyHandler?(isUpdateReady) }
    }

    override init() {
        super.init()
    }

    var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
    }

    var automaticallyChecksForUpdates: Bool {
        get { updaterController.updater.automaticallyChecksForUpdates }
        set { updaterController.updater.automaticallyChecksForUpdates = newValue }
    }

    var automaticallyDownloadsUpdates: Bool {
        get { updaterController.updater.automaticallyDownloadsUpdates }
        set { updaterController.updater.automaticallyDownloadsUpdates = newValue }
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

    func installUpdate() {
        guard let immediateInstallHandler else {
            checkForUpdates()
            return
        }
        immediateInstallHandler.install()
    }

    func observeCanCheckForUpdates(_ handler: @escaping @MainActor (Bool) -> Void) -> AnyObject? {
        updaterController.updater.observe(\.canCheckForUpdates, options: [.initial, .new]) { updater, _ in
            Task { @MainActor in
                handler(updater.canCheckForUpdates)
            }
        }
    }

    func observeUpdateReady(_ handler: @escaping @MainActor (Bool) -> Void) -> AnyObject? {
        updateReadyHandler = handler
        handler(isUpdateReady)
        return nil
    }

    nonisolated func updater(
        _ updater: SPUUpdater,
        willInstallUpdateOnQuit item: SUAppcastItem,
        immediateInstallationBlock immediateInstallHandler: @escaping () -> Void) -> Bool
    {
        _ = updater
        _ = item
        let handler = ImmediateInstallHandler(immediateInstallHandler)
        Task { @MainActor in
            self.immediateInstallHandler = handler
            self.isUpdateReady = true
        }
        return true
    }

    nonisolated func updater(_ updater: SPUUpdater, failedToDownloadUpdate item: SUAppcastItem, error: Error) {
        _ = updater
        _ = item
        clearReadyState(error: error)
    }

    nonisolated func userDidCancelDownload(_ updater: SPUUpdater) {
        _ = updater
        clearReadyState()
    }

    nonisolated func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        _ = updater
        clearReadyState(error: error)
    }

    nonisolated func updater(
        _ updater: SPUUpdater,
        userDidMake choice: SPUUserUpdateChoice,
        forUpdate updateItem: SUAppcastItem,
        state: SPUUserUpdateState)
    {
        _ = updater
        _ = updateItem
        let downloaded = state.stage == .downloaded
        Task { @MainActor in
            switch choice {
            case .dismiss:
                self.isUpdateReady = downloaded
            case .install, .skip:
                self.immediateInstallHandler = nil
                self.isUpdateReady = false
            @unknown default:
                self.immediateInstallHandler = nil
                self.isUpdateReady = false
            }
        }
    }

    nonisolated private func clearReadyState(error: Error? = nil) {
        if let error {
            logger.error("Sparkle update failed: \(error.localizedDescription, privacy: .public)")
        }
        Task { @MainActor in
            self.immediateInstallHandler = nil
            self.isUpdateReady = false
        }
    }
}
