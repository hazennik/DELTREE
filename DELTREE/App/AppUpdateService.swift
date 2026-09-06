import Foundation
import Observation

@MainActor
protocol AppUpdating: AnyObject {
    var canCheckForUpdates: Bool { get }
    var automaticallyChecksForUpdates: Bool { get set }
    var automaticallyDownloadsUpdates: Bool { get set }
    var isUpdateReady: Bool { get }

    func start()
    func checkForUpdates()
    func installUpdate()
    func observeCanCheckForUpdates(_ handler: @escaping @MainActor (Bool) -> Void) -> AnyObject?
    func observeUpdateReady(_ handler: @escaping @MainActor (Bool) -> Void) -> AnyObject?
}

struct AppUpdateConfiguration: Equatable, Sendable {
    static let feedURLKey = "SUFeedURL"
    static let publicEDKeyKey = "SUPublicEDKey"

    var feedURL: String
    var publicEDKey: String

    static func current(bundle: Bundle = .main) -> AppUpdateConfiguration {
        AppUpdateConfiguration(
            feedURL: bundle.object(forInfoDictionaryKey: feedURLKey) as? String ?? "",
            publicEDKey: bundle.object(forInfoDictionaryKey: publicEDKeyKey) as? String ?? "")
    }

    var isComplete: Bool {
        guard URL(string: feedURL)?.scheme == "https" else {
            return false
        }
        return publicEDKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}

@MainActor
@Observable
final class AppUpdateService {
    private(set) var canCheckForUpdates = false
    private(set) var isUpdateReady = false
    var automaticallyChecksForUpdates = false {
        didSet {
            updater?.automaticallyChecksForUpdates = automaticallyChecksForUpdates
            if automaticallyChecksForUpdates == false, automaticallyDownloadsUpdates {
                automaticallyDownloadsUpdates = false
            }
        }
    }

    var automaticallyDownloadsUpdates = false {
        didSet { updater?.automaticallyDownloadsUpdates = automaticallyDownloadsUpdates }
    }

    let isVisible: Bool

    @ObservationIgnored private var updater: (any AppUpdating)?
    @ObservationIgnored private var canCheckObservation: AnyObject?
    @ObservationIgnored private var updateReadyObservation: AnyObject?

    init(
        distributionChannel: DistributionChannel,
        configuration: AppUpdateConfiguration,
        makeUpdater: () -> any AppUpdating)
    {
        isVisible = distributionChannel.allowsSparkleUpdates && configuration.isComplete
        guard isVisible else {
            return
        }

        let updater = makeUpdater()
        self.updater = updater
        canCheckForUpdates = updater.canCheckForUpdates
        automaticallyChecksForUpdates = updater.automaticallyChecksForUpdates
        automaticallyDownloadsUpdates = updater.automaticallyDownloadsUpdates
        isUpdateReady = updater.isUpdateReady
        canCheckObservation = updater.observeCanCheckForUpdates { [weak self] canCheckForUpdates in
            self?.canCheckForUpdates = canCheckForUpdates
        }
        updateReadyObservation = updater.observeUpdateReady { [weak self] isUpdateReady in
            self?.isUpdateReady = isUpdateReady
        }
        updater.start()
    }

    static func disabled() -> AppUpdateService {
        AppUpdateService(
            distributionChannel: .unknown,
            configuration: AppUpdateConfiguration(feedURL: "", publicEDKey: ""),
            makeUpdater: DisabledAppUpdater.init)
    }

    static func preview(isUpdateReady: Bool = true) -> AppUpdateService {
        AppUpdateService(
            distributionChannel: .developerID,
            configuration: AppUpdateConfiguration(
                feedURL: "https://example.com/appcast.xml",
                publicEDKey: "preview-key"),
            makeUpdater: { PreviewAppUpdater(isUpdateReady: isUpdateReady) })
    }

    func checkForUpdates() {
        updater?.checkForUpdates()
    }

    func installUpdate() {
        updater?.installUpdate()
    }
}

@MainActor
private final class DisabledAppUpdater: AppUpdating {
    let canCheckForUpdates = false
    var automaticallyChecksForUpdates = false
    var automaticallyDownloadsUpdates = false
    let isUpdateReady = false

    func start() {}
    func checkForUpdates() {}
    func installUpdate() {}

    func observeCanCheckForUpdates(_ handler: @escaping @MainActor (Bool) -> Void) -> AnyObject? {
        nil
    }

    func observeUpdateReady(_ handler: @escaping @MainActor (Bool) -> Void) -> AnyObject? {
        nil
    }
}

@MainActor
private final class PreviewAppUpdater: AppUpdating {
    let canCheckForUpdates = true
    var automaticallyChecksForUpdates = true
    var automaticallyDownloadsUpdates = false
    let isUpdateReady: Bool

    init(isUpdateReady: Bool) {
        self.isUpdateReady = isUpdateReady
    }

    func start() {}
    func checkForUpdates() {}
    func installUpdate() {}

    func observeCanCheckForUpdates(_ handler: @escaping @MainActor (Bool) -> Void) -> AnyObject? {
        nil
    }

    func observeUpdateReady(_ handler: @escaping @MainActor (Bool) -> Void) -> AnyObject? {
        nil
    }
}
