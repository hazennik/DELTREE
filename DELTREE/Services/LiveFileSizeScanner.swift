import Foundation

struct LiveFileSizeScanner: FileSizeScanning, @unchecked Sendable {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func size(of url: URL) -> FileSizeResult {
        if Task.isCancelled {
            return FileSizeResult(bytes: 0, unreadablePaths: [])
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return FileSizeResult(bytes: 0, unreadablePaths: [])
        }

        guard isSymbolicLink(at: url) == false else {
            return FileSizeResult(bytes: 0, unreadablePaths: [])
        }

        if isDirectory.boolValue {
            return directorySize(of: url)
        }

        return fileSize(of: url)
    }

    private func directorySize(of url: URL) -> FileSizeResult {
        let keys: Set<URLResourceKey> = [
            .isDirectoryKey,
            .isRegularFileKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .fileAllocatedSizeKey,
            .totalFileAllocatedSizeKey,
        ]
        let unreadableCollector = LockedPathCollector()
        guard let enumerator = fileManager.enumerator(
            at: url,
            includingPropertiesForKeys: Array(keys),
            options: [],
            errorHandler: { url, _ in
                unreadableCollector.append(url.path)
                return true
            })
        else {
            return FileSizeResult(bytes: 0, unreadablePaths: [url.path])
        }

        var bytes: Int64 = 0
        for case let itemURL as URL in enumerator {
            if Task.isCancelled {
                enumerator.skipDescendants()
                break
            }

            guard let values = try? itemURL.resourceValues(forKeys: keys) else {
                unreadableCollector.append(itemURL.path)
                continue
            }

            if values.isSymbolicLink == true {
                if values.isDirectory == true {
                    enumerator.skipDescendants()
                }
                continue
            }

            if values.isRegularFile == true {
                bytes += Self.byteCount(from: values)
            }
        }

        return FileSizeResult(bytes: bytes, unreadablePaths: unreadableCollector.paths)
    }

    private func fileSize(of url: URL) -> FileSizeResult {
        let keys: Set<URLResourceKey> = [
            .isRegularFileKey,
            .isSymbolicLinkKey,
            .fileSizeKey,
            .fileAllocatedSizeKey,
            .totalFileAllocatedSizeKey,
        ]
        guard let values = try? url.resourceValues(forKeys: keys) else {
            return FileSizeResult(bytes: 0, unreadablePaths: [url.path])
        }
        guard values.isSymbolicLink != true, values.isRegularFile == true else {
            return FileSizeResult(bytes: 0, unreadablePaths: [])
        }
        return FileSizeResult(bytes: Self.byteCount(from: values), unreadablePaths: [])
    }

    private func isSymbolicLink(at url: URL) -> Bool {
        (try? url.resourceValues(forKeys: [.isSymbolicLinkKey]).isSymbolicLink) == true
    }

    private static func byteCount(from values: URLResourceValues) -> Int64 {
        Int64(values.totalFileAllocatedSize ?? values.fileAllocatedSize ?? values.fileSize ?? 0)
    }
}

private final class LockedPathCollector: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: [String] = []

    var paths: [String] {
        lock.lock()
        defer { lock.unlock() }
        return storage
    }

    func append(_ path: String) {
        lock.lock()
        defer { lock.unlock() }
        storage.append(path)
    }
}
