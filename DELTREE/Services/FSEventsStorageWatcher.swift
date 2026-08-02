import CoreServices
import Foundation

final class FSEventsStorageWatcher: StorageWatching, @unchecked Sendable {
    var onChange: (@Sendable ([String]) -> Void)?

    private let queue = DispatchQueue(label: "com.infrallabs.deltree.storage-watcher", qos: .utility)
    private var stream: FSEventStreamRef?
    private var watchedPaths: [String] = []

    func start(paths: [String]) {
        stop()
        watchedPaths = paths.filter { FileManager.default.fileExists(atPath: $0) }
        guard watchedPaths.isEmpty == false else {
            return
        }

        var context = FSEventStreamContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil,
            release: nil,
            copyDescription: nil)

        stream = FSEventStreamCreate(
            nil,
            Self.callback,
            &context,
            watchedPaths as CFArray,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            5.0,
            FSEventStreamCreateFlags(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents))

        guard let stream else {
            return
        }

        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
    }

    func stop() {
        guard let stream else {
            return
        }
        FSEventStreamStop(stream)
        FSEventStreamInvalidate(stream)
        FSEventStreamRelease(stream)
        self.stream = nil
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
