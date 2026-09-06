import Foundation

struct FileSystemIdentity: Hashable, Codable, Sendable {
    var volumeNumber: UInt64
    var fileNumber: UInt64
    var fileType: String
    var modifiedAt: Date?
}

enum FileSystemIdentityReader {
    static func identity(
        for url: URL,
        fileManager: FileManager = .default) -> FileSystemIdentity?
    {
        guard let attributes = try? fileManager.attributesOfItem(atPath: url.standardizedFileURL.path),
              let volumeNumber = (attributes[.systemNumber] as? NSNumber)?.uint64Value,
              let fileNumber = (attributes[.systemFileNumber] as? NSNumber)?.uint64Value,
              let fileType = attributes[.type] as? FileAttributeType
        else {
            return nil
        }

        return FileSystemIdentity(
            volumeNumber: volumeNumber,
            fileNumber: fileNumber,
            fileType: fileType.rawValue,
            modifiedAt: attributes[.modificationDate] as? Date)
    }
}
