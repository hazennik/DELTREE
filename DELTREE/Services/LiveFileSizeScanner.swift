import Foundation

struct LiveFileSizeScanner: FileSizeScanning, @unchecked Sendable {
    private let fileManager: FileManager
    private let budget: FileSizeScanBudget

    init(fileManager: FileManager = .default, budget: FileSizeScanBudget = .production) {
        self.fileManager = fileManager
        self.budget = budget
    }

    func size(of url: URL) -> FileSizeResult {
        if Task.isCancelled {
            return FileSizeResult(
                bytes: 0,
                unreadablePaths: [],
                isComplete: false,
                incompleteReason: "Scan cancelled before it started.")
        }

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
            return FileSizeResult(bytes: 0, unreadablePaths: [])
        }

        guard isSymbolicLink(at: url) == false else {
            return FileSizeResult(bytes: 0, unreadablePaths: [], scannedEntryCount: 1)
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
            return FileSizeResult(
                bytes: 0,
                unreadablePaths: [url.path],
                isComplete: false,
                incompleteReason: "Directory could not be enumerated.")
        }

        var bytes: Int64 = 0
        var scannedEntryCount = 0
        var isComplete = true
        var incompleteReason: String?
        for case let itemURL as URL in enumerator {
            if Task.isCancelled {
                enumerator.skipDescendants()
                isComplete = false
                incompleteReason = "Scan cancelled."
                break
            }

            if let maxEntryCount = budget.maxEntryCount, scannedEntryCount >= maxEntryCount {
                enumerator.skipDescendants()
                isComplete = false
                incompleteReason = "Entry budget exceeded after \(maxEntryCount) entries."
                break
            }
            scannedEntryCount += 1

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

        return FileSizeResult(
            bytes: bytes,
            unreadablePaths: unreadableCollector.paths,
            scannedEntryCount: scannedEntryCount,
            isComplete: isComplete,
            incompleteReason: incompleteReason)
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
            return FileSizeResult(
                bytes: 0,
                unreadablePaths: [url.path],
                scannedEntryCount: 1,
                isComplete: false,
                incompleteReason: "File metadata could not be read.")
        }
        guard values.isSymbolicLink != true, values.isRegularFile == true else {
            return FileSizeResult(bytes: 0, unreadablePaths: [], scannedEntryCount: 1)
        }
        return FileSizeResult(bytes: Self.byteCount(from: values), unreadablePaths: [], scannedEntryCount: 1)
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
