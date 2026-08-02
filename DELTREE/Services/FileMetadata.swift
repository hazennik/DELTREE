import Foundation

struct FileMetadata: Equatable, Sendable {
    var createdAt: Date?
    var modifiedAt: Date?
    var accessedAt: Date?
    var isDirectory: Bool
}

enum FileMetadataReader {
    static func metadata(for url: URL) -> FileMetadata {
        let values = try? url.resourceValues(forKeys: [
            .creationDateKey,
            .contentModificationDateKey,
            .contentAccessDateKey,
            .isDirectoryKey,
        ])
        return FileMetadata(
            createdAt: values?.creationDate,
            modifiedAt: values?.contentModificationDate,
            accessedAt: values?.contentAccessDate,
            isDirectory: values?.isDirectory == true)
    }
}
