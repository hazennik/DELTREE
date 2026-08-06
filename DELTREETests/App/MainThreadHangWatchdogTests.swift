import Foundation
import Testing
@testable import DELTREE

@MainActor
struct MainThreadHangWatchdogTests {
    @Test func disabledWatchdogDoesNotSchedule() {
        let harness = WatchdogHarness()
        let watchdog = harness.makeWatchdog(configuration: .disabled)

        watchdog.start()
        watchdog.recordBreadcrumb("scan.apply")
        harness.advance(by: 10)
        harness.tick()

        #expect(harness.scheduledInterval == nil)
        #expect(harness.events.isEmpty)
        #expect(harness.samples.isEmpty)
    }

    @Test func lateMainThreadTickLogsBreadcrumbsAndCapturesSample() {
        let harness = WatchdogHarness()
        let watchdog = harness.makeWatchdog(configuration: .init(
            isEnabled: true,
            checkInterval: 0.5,
            hangThreshold: 2,
            maxBreadcrumbCount: 2,
            sampleCaptureEnabled: true))

        watchdog.start()
        watchdog.recordBreadcrumb("scan.apply.begin")
        watchdog.recordBreadcrumb("persistence.scan.begin")
        watchdog.recordBreadcrumb("persistence.scan.end")
        harness.advance(by: 2.5)
        harness.tick()

        #expect(harness.scheduledInterval == 0.5)
        #expect(harness.events.count == 1)
        #expect(harness.samples.count == 1)
        #expect(harness.events.first?.duration == 2.5)
        #expect(harness.events.first?.breadcrumbs.map(\.name) == [
            "persistence.scan.begin",
            "persistence.scan.end",
        ])
    }

    @Test func onTimeMainThreadTickDoesNotLog() {
        let harness = WatchdogHarness()
        let watchdog = harness.makeWatchdog(configuration: .init(
            isEnabled: true,
            checkInterval: 1,
            hangThreshold: 2,
            maxBreadcrumbCount: 4,
            sampleCaptureEnabled: true))

        watchdog.start()
        watchdog.recordBreadcrumb("cleanup.execute.begin")
        harness.advance(by: 1.5)
        harness.tick()

        #expect(harness.events.isEmpty)
        #expect(harness.samples.isEmpty)
    }

    @Test func stopCancelsScheduledTimer() {
        let harness = WatchdogHarness()
        let watchdog = harness.makeWatchdog(configuration: .init(
            isEnabled: true,
            checkInterval: 1,
            hangThreshold: 2,
            maxBreadcrumbCount: 4,
            sampleCaptureEnabled: false))

        watchdog.start()
        watchdog.stop()

        #expect(harness.didCancel)
    }

    @Test func withBreadcrumbRecordsBeginAndEndMarkers() {
        let harness = WatchdogHarness()
        let watchdog = harness.makeWatchdog(configuration: .init(
            isEnabled: true,
            checkInterval: 1,
            hangThreshold: 2,
            maxBreadcrumbCount: 4,
            sampleCaptureEnabled: false))

        watchdog.start()
        let value = watchdog.withBreadcrumb("report.write") {
            "written"
        }
        harness.advance(by: 3)
        harness.tick()

        #expect(value == "written")
        #expect(harness.events.first?.breadcrumbs.map(\.name) == [
            "report.write.begin",
            "report.write.end",
        ])
    }

    @Test func defaultConfigurationHonorsEnvironmentOverrides() {
        let enabled = MainThreadHangWatchdog.Configuration.defaults(environment: [
            "DELTREE_MAIN_THREAD_HANG_WATCHDOG": "1",
            "DELTREE_MAIN_THREAD_HANG_CHECK_SECONDS": "3",
            "DELTREE_MAIN_THREAD_HANG_THRESHOLD_SECONDS": "7",
            "DELTREE_MAIN_THREAD_HANG_BREADCRUMBS": "5",
            "DELTREE_MAIN_THREAD_HANG_SAMPLE": "yes",
        ])
        let disabled = MainThreadHangWatchdog.Configuration.defaults(environment: [
            "DELTREE_MAIN_THREAD_HANG_WATCHDOG": "0",
        ])

        #expect(enabled.isEnabled)
        #expect(enabled.checkInterval == 3)
        #expect(enabled.hangThreshold == 7)
        #expect(enabled.maxBreadcrumbCount == 5)
        #expect(enabled.sampleCaptureEnabled)
        #expect(disabled.isEnabled == false)
    }
}

@MainActor
private final class WatchdogHarness {
    var currentDate = Date(timeIntervalSince1970: 1_000)
    var scheduledInterval: TimeInterval?
    var scheduledAction: (@MainActor () -> Void)?
    var didCancel = false
    var events: [MainThreadHangWatchdog.HangEvent] = []
    var samples: [MainThreadHangWatchdog.HangEvent] = []

    func makeWatchdog(configuration: MainThreadHangWatchdog.Configuration) -> MainThreadHangWatchdog {
        MainThreadHangWatchdog(
            configuration: configuration,
            now: { self.currentDate },
            schedule: { interval, action in
                self.scheduledInterval = interval
                self.scheduledAction = action
                return {
                    self.didCancel = true
                }
            },
            logEvent: { event in
                self.events.append(event)
            },
            captureSample: { event in
                self.samples.append(event)
            })
    }

    func advance(by seconds: TimeInterval) {
        currentDate = currentDate.addingTimeInterval(seconds)
    }

    func tick() {
        scheduledAction?()
    }
}
