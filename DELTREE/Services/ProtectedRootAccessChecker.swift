import Foundation

enum ProtectedRootAccessResult: Equatable, Sendable {
    case available
    case missing
    case unreadable
}

protocol ProtectedRootAccessChecking: Sendable {
    func checkAccess(to root: URL) -> ProtectedRootAccessResult
}

struct LiveProtectedRootAccessChecker: ProtectedRootAccessChecking, @unchecked Sendable {
    private let fileManager: FileManager

    init(fileManager: FileManager = .default) {
        self.fileManager = fileManager
    }

    func checkAccess(to root: URL) -> ProtectedRootAccessResult {
        do {
            _ = try fileManager.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles])
            return .available
        } catch {
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain,
               CocoaError.Code(rawValue: nsError.code) == .fileNoSuchFile
            {
                return .missing
            }
            return .unreadable
        }
    }
}
