import Foundation

struct FileSizeResult: Equatable, Sendable {
    var bytes: Int64
    var unreadablePaths: [String]
}
