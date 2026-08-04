import Foundation
import OSLog

#if canImport(Darwin)
import Darwin
#endif

enum MemoryPressureLevel: String, Equatable, Sendable {
    case warning
    case critical
}

struct MemoryPressureTrimSummary: Equatable, Sendable {
    var level: MemoryPressureLevel
    var releasedPreviousSnapshot: Bool
    var scanHistoryTrimmedCount: Int
    var cleanupHistoryTrimmedCount: Int
    var deltaHistoryTrimmedCount: Int
    var diagnosticsTrimmedCount: Int

    var totalTrimmedCount: Int {
        scanHistoryTrimmedCount +
            cleanupHistoryTrimmedCount +
            deltaHistoryTrimmedCount +
            diagnosticsTrimmedCount
    }
}

enum MemoryPressureRelief {
    @discardableResult
    static func releaseFreeMallocPages() -> Int {
        #if canImport(Darwin)
        malloc_zone_pressure_relief(nil, 0)
        #else
        0
        #endif
    }
}

final class MemoryPressureMonitor: @unchecked Sendable {
    typealias ReliefHandler = () -> Int
    typealias EventHandler = (_ level: MemoryPressureLevel) -> Void

    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "com.infralabs.DELTREE",
        category: "MemoryPressure")

    private let queue: DispatchQueue
    private let reliefHandler: ReliefHandler
    private let eventHandler: EventHandler
    private var source: DispatchSourceMemoryPressure?

    init(
        queue: DispatchQueue = DispatchQueue(label: "com.infralabs.deltree.memory-pressure", qos: .utility),
        reliefHandler: @escaping ReliefHandler = MemoryPressureRelief.releaseFreeMallocPages,
        eventHandler: @escaping EventHandler)
    {
        self.queue = queue
        self.reliefHandler = reliefHandler
        self.eventHandler = eventHandler
    }

    func start() {
        guard source == nil else {
            return
        }

        let source = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: queue)
        source.setEventHandler { [weak self, weak source] in
            guard let self, let source else {
                return
            }
            self.handle(events: source.data)
        }
        source.resume()
        self.source = source
    }

    func stop() {
        source?.cancel()
        source = nil
    }

    deinit {
        stop()
    }

    func handle(events: DispatchSource.MemoryPressureEvent) {
        handle(level: Self.level(for: events))
    }

    func handle(level: MemoryPressureLevel) {
        let releasedBytes = reliefHandler()
        Self.logger.info(
            "Handling \(level.rawValue, privacy: .public) memory pressure; malloc relief released \(releasedBytes, privacy: .public) bytes.")
        eventHandler(level)
    }

    static func level(for events: DispatchSource.MemoryPressureEvent) -> MemoryPressureLevel {
        if events.contains(.critical) {
            return .critical
        }
        return .warning
    }
}
