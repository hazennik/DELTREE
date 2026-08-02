import Foundation

struct LiveDiskSpaceProvider: DiskSpaceProviding {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func availableBytes(for url: URL) -> Int64? {
        guard let attributes = try? fileManager.attributesOfFileSystem(forPath: url.path) else {
            return nil
        }
        if let freeSize = attributes[.systemFreeSize] as? NSNumber {
            return freeSize.int64Value
        }
        return nil
    }
}
