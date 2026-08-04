import Foundation
import Observation

@MainActor
protocol AppUpdating: AnyObject {
    var canCheckForUpdates: Bool { get }

    func start()
    func checkForUpdates()
    func observeCanCheckForUpdates(_ handler: @escaping @MainActor (Bool) -> Void) -> AnyObject?
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

    let isVisible: Bool

    @ObservationIgnored private var updater: (any AppUpdating)?
    @ObservationIgnored private var canCheckObservation: AnyObject?

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
        canCheckObservation = updater.observeCanCheckForUpdates { [weak self] canCheckForUpdates in
            self?.canCheckForUpdates = canCheckForUpdates
        }
        updater.start()
    }

    static func disabled() -> AppUpdateService {
        AppUpdateService(
            distributionChannel: .unknown,
            configuration: AppUpdateConfiguration(feedURL: "", publicEDKey: ""),
            makeUpdater: DisabledAppUpdater.init)
    }

    func checkForUpdates() {
        updater?.checkForUpdates()
    }
}

@MainActor
private final class DisabledAppUpdater: AppUpdating {
    let canCheckForUpdates = false

    func start() {}
    func checkForUpdates() {}

    func observeCanCheckForUpdates(_ handler: @escaping @MainActor (Bool) -> Void) -> AnyObject? {
        nil
    }
}
