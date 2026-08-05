import CoreServices
import Foundation

final class FSEventsStorageWatcher: StorageWatching, @unchecked Sendable {
    var onChange: (@Sendable ([String]) -> Void)? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return changeHandler
        }
        set {
            lock.lock()
            changeHandler = newValue
            lock.unlock()
        }
    }

    private let queue = DispatchQueue(label: "com.infrallabs.deltree.storage-watcher", qos: .utility)
    private let lock = NSLock()
    private var changeHandler: (@Sendable ([String]) -> Void)?
    private var stream: FSEventStreamRef?
    private var watchedPaths: [String] = []

    func start(paths: [String]) {
        stop()
        let existingPaths = paths.filter { FileManager.default.fileExists(atPath: $0) }
        guard existingPaths.isEmpty == false else {
            return
        }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil)

        let createdStream = FSEventStreamCreate(
            nil,
            Self.callback,
            &context,
            existingPaths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            5.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes))

        guard let createdStream else {
            return
        }

        FSEventStreamSetDispatchQueue(createdStream, queue)
        lock.lock()
        watchedPaths = existingPaths
        stream = createdStream
        lock.unlock()
        FSEventStreamStart(createdStream)
    }

    func stop() {
        lock.lock()
        let stream = stream
        self.stream = nil
        watchedPaths = []
        lock.unlock()

        guard let stream else {
            return
        }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
    }

    deinit {
        stop()
    }

    private static let callback: FSEventStreamCallback = { _, info, _, eventPaths, _, _ in
        guard let info else {
            return
        }

        let watcher = Unmanaged<FSEventsStorageWatcher>.fromOpaque(info).takeUnretainedValue()
        let paths = unsafeBitCast(eventPaths, to: NSArray.self) as? [String] ?? []
        watcher.onChange?(paths)
    }
}
