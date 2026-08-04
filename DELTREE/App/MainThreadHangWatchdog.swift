import Foundation
import OSLog

@MainActor
final class MainThreadHangWatchdog {
    struct Configuration: Equatable, Sendable {
        var isEnabled: Bool
        var checkInterval: TimeInterval
        var hangThreshold: TimeInterval
        var maxBreadcrumbCount: Int
        var sampleCaptureEnabled: Bool

        static let disabled = Configuration(
            isEnabled: false,
            checkInterval: 1,
            hangThreshold: 2,
            maxBreadcrumbCount: 32,
            sampleCaptureEnabled: false)

        static func defaults(environment: [String: String] = ProcessInfo.processInfo.environment) -> Configuration {
            let explicitEnabled = Self.booleanValue(environment["DELTREE_MAIN_THREAD_HANG_WATCHDOG"])
            #if DEBUG
            let debugDefaultEnabled = true
            #else
            let debugDefaultEnabled = false
            #endif

            return Configuration(
                isEnabled: explicitEnabled ?? debugDefaultEnabled,
                checkInterval: Self.positiveInterval(
                    environment["DELTREE_MAIN_THREAD_HANG_CHECK_SECONDS"],
                    defaultValue: 1),
                hangThreshold: Self.positiveInterval(
                    environment["DELTREE_MAIN_THREAD_HANG_THRESHOLD_SECONDS"],
                    defaultValue: 2),
                maxBreadcrumbCount: max(
                    1,
                    Int(environment["DELTREE_MAIN_THREAD_HANG_BREADCRUMBS"] ?? "") ?? 32),
                sampleCaptureEnabled: Self.booleanValue(environment["DELTREE_MAIN_THREAD_HANG_SAMPLE"]) ?? false)
        }

        private static func booleanValue(_ value: String?) -> Bool? {
            switch value?.lowercased() {
            case "1", "true", "yes", "on":
                true
            case "0", "false", "no", "off":
                false
            default:
                nil
            }
        }

        private static func positiveInterval(_ value: String?, defaultValue: TimeInterval) -> TimeInterval {
            guard let value,
                  let interval = TimeInterval(value),
                  interval > 0
            else {
                return defaultValue
            }
            return interval
        }
    }

    struct Breadcrumb: Equatable, Sendable {
        var name: String
        var recordedAt: Date
    }

    struct HangEvent: Equatable, Sendable {
        var detectedAt: Date
        var duration: TimeInterval
        var threshold: TimeInterval
        var breadcrumbs: [Breadcrumb]

        var breadcrumbSummary: String {
            breadcrumbs.map { "\($0.name)@\($0.recordedAt.timeIntervalSince1970)" }.joined(separator: " > ")
        }
    }

    typealias Now = @MainActor () -> Date
    typealias Schedule = @MainActor (
        _ interval: TimeInterval,
        _ action: @escaping @MainActor () -> Void)
        -> @MainActor () -> Void
    typealias EventHandler = @MainActor (_ event: HangEvent) -> Void

    nonisolated private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.infralabs.DELTREE",
        category: "MainThreadHangWatchdog")

    private let configuration: Configuration
    private let now: Now
    private let schedule: Schedule
    private let logEvent: EventHandler
    private let captureSample: EventHandler
    private var cancelTimer: (@MainActor () -> Void)?
    private var lastCheckAt: Date?
    private var breadcrumbs: [Breadcrumb] = []

    init(
        configuration: Configuration = .defaults(),
        now: @escaping Now = { Date() },
        schedule: @escaping Schedule = MainThreadHangWatchdog.defaultSchedule,
        logEvent: @escaping EventHandler = MainThreadHangWatchdog.defaultLogEvent,
        captureSample: @escaping EventHandler = MainThreadHangWatchdog.defaultCaptureSample)
    {
        self.configuration = configuration
        self.now = now
        self.schedule = schedule
        self.logEvent = logEvent
        self.captureSample = captureSample
    }

    static func makeDefault(environment: [String: String] = ProcessInfo.processInfo.environment) -> MainThreadHangWatchdog {
        MainThreadHangWatchdog(configuration: .defaults(environment: environment))
    }

    static func disabled() -> MainThreadHangWatchdog {
        MainThreadHangWatchdog(configuration: .disabled)
    }

    func start() {
        guard configuration.isEnabled, cancelTimer == nil else {
            return
        }
        lastCheckAt = now()
        cancelTimer = schedule(configuration.checkInterval) { [weak self] in
            self?.checkForHang()
        }
        Self.logger.debug("Main thread hang watchdog started.")
    }

    func stop() {
        cancelTimer?()
        cancelTimer = nil
        lastCheckAt = nil
    }

    func recordBreadcrumb(_ name: String) {
        guard configuration.isEnabled else {
            return
        }
        breadcrumbs.append(Breadcrumb(name: name, recordedAt: now()))
        if breadcrumbs.count > configuration.maxBreadcrumbCount {
            breadcrumbs.removeFirst(breadcrumbs.count - configuration.maxBreadcrumbCount)
        }
    }

    @discardableResult
    func withBreadcrumb<T>(_ name: String, operation: () throws -> T) rethrows -> T {
        recordBreadcrumb("\(name).begin")
        defer { recordBreadcrumb("\(name).end") }
        return try operation()
    }

    @discardableResult
    func withBreadcrumb<T>(_ name: String, operation: () async throws -> T) async rethrows -> T {
        recordBreadcrumb("\(name).begin")
        defer { recordBreadcrumb("\(name).end") }
        return try await operation()
    }

    private func checkForHang() {
        guard configuration.isEnabled else {
            return
        }
        let currentDate = now()
        defer { lastCheckAt = currentDate }
        guard let lastCheckAt else {
            return
        }

        let duration = currentDate.timeIntervalSince(lastCheckAt)
        guard duration >= configuration.hangThreshold else {
            return
        }

        let event = HangEvent(
            detectedAt: currentDate,
            duration: duration,
            threshold: configuration.hangThreshold,
            breadcrumbs: breadcrumbs)
        logEvent(event)
        if configuration.sampleCaptureEnabled {
            captureSample(event)
        }
    }

    private static func defaultSchedule(
        interval: TimeInterval,
        action: @escaping @MainActor () -> Void)
        -> @MainActor () -> Void
    {
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            Task { @MainActor in
                action()
            }
        }
        return {
            timer.invalidate()
        }
    }

    private static func defaultLogEvent(_ event: HangEvent) {
        logger.warning(
            """
            Main thread hang suspected: duration=\(event.duration, privacy: .public), \
            threshold=\(event.threshold, privacy: .public), \
            breadcrumbs=\(event.breadcrumbSummary, privacy: .public)
            """)
    }

    private static func defaultCaptureSample(_ event: HangEvent) {
        let sampleToolPath = "/usr/bin/sample"
        guard FileManager.default.isExecutableFile(atPath: sampleToolPath) else {
            logger.error("Could not capture hang sample because /usr/bin/sample is unavailable.")
            return
        }

        let processIdentifier = ProcessInfo.processInfo.processIdentifier
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("DELTREE-main-thread-hang-\(processIdentifier)-\(Int(event.detectedAt.timeIntervalSince1970)).sample.txt")

        DispatchQueue.global(qos: .utility).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: sampleToolPath)
            process.arguments = [String(processIdentifier), "1", "-file", outputURL.path]
            do {
                try process.run()
                process.waitUntilExit()
                logger.info("Captured main thread hang sample at \(outputURL.path, privacy: .private).")
            } catch {
                logger.error("Could not capture main thread hang sample: \(error.localizedDescription, privacy: .public).")
            }
        }
    }
}
