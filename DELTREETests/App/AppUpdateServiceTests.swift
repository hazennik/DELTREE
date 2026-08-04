import Foundation
import Testing
@testable import DELTREE

@MainActor
struct AppUpdateServiceTests {
    @Test func developerIDWithCompleteConfigurationStartsUpdater() {
        let updater = RecordingAppUpdater(canCheckForUpdates: true)
        let service = AppUpdateService(
            distributionChannel: .developerID,
            configuration: .complete,
            makeUpdater: { updater })

        #expect(service.isVisible)
        #expect(service.canCheckForUpdates)
        #expect(updater.startCallCount == 1)

        updater.emitCanCheckForUpdates(false)

        #expect(service.canCheckForUpdates == false)
    }

    @Test func debugWithCompleteConfigurationStartsUpdater() {
        let updater = RecordingAppUpdater(canCheckForUpdates: true)
        let service = AppUpdateService(
            distributionChannel: .debug,
            configuration: .complete,
            makeUpdater: { updater })

        #expect(service.isVisible)
        #expect(updater.startCallCount == 1)
    }

    @Test func homebrewNeverStartsUpdater() {
        let updater = RecordingAppUpdater(canCheckForUpdates: true)
        let service = AppUpdateService(
            distributionChannel: .homebrew,
            configuration: .complete,
            makeUpdater: { updater })

        #expect(service.isVisible == false)
        #expect(service.canCheckForUpdates == false)
        #expect(updater.startCallCount == 0)
    }

    @Test func missingSparkleConfigurationDisablesUpdater() {
        let updater = RecordingAppUpdater(canCheckForUpdates: true)
        let service = AppUpdateService(
            distributionChannel: .developerID,
            configuration: AppUpdateConfiguration(feedURL: "https://example.com/appcast.xml", publicEDKey: ""),
            makeUpdater: { updater })

        #expect(service.isVisible == false)
        #expect(updater.startCallCount == 0)
    }

    @Test func feedURLMustUseHTTPS() {
        let updater = RecordingAppUpdater(canCheckForUpdates: true)
        let service = AppUpdateService(
            distributionChannel: .developerID,
            configuration: AppUpdateConfiguration(feedURL: "http://example.com/appcast.xml", publicEDKey: "public-key"),
            makeUpdater: { updater })

        #expect(service.isVisible == false)
        #expect(updater.startCallCount == 0)
    }
}

private extension AppUpdateConfiguration {
    static let complete = AppUpdateConfiguration(
        feedURL: "https://github.com/hazennik/DELTREE/releases/latest/download/appcast.xml",
        publicEDKey: "public-key")
}

@MainActor
private final class RecordingAppUpdater: AppUpdating {
    private var handler: (@MainActor (Bool) -> Void)?

    var canCheckForUpdates: Bool
    var startCallCount = 0
    var checkCallCount = 0

    init(canCheckForUpdates: Bool) {
        self.canCheckForUpdates = canCheckForUpdates
    }

    func start() {
        startCallCount += 1
    }

    func checkForUpdates() {
        checkCallCount += 1
    }

    func observeCanCheckForUpdates(_ handler: @escaping @MainActor (Bool) -> Void) -> AnyObject? {
        self.handler = handler
        return ObservationToken()
    }

    func emitCanCheckForUpdates(_ value: Bool) {
        canCheckForUpdates = value
        handler?(value)
    }
}

private final class ObservationToken {}
