import Foundation

struct FileManagerTrashService: TrashServicing, @unchecked Sendable {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func moveToTrash(_ item: StorageItem) async throws {
        try await Task.detached(priority: .utility) {
            let url = URL(fileURLWithPath: item.path)
            var resultingURL: NSURL?
            try fileManager.trashItem(at: url, resultingItemURL: &resultingURL)
        }.value
    }
}
