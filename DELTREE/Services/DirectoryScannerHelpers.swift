import Foundation

enum DirectoryScannerHelpers {
    static func topLevelCandidates(root: URL, context: DomainScanContext) -> [URL] {
        var isDirectory: ObjCBool = false
        guard context.fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory) else {
            return []
        }
        guard isDirectory.boolValue else {
            return [root]
        }
        return (try? context.fileManager.contentsOfDirectory(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .isRegularFileKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles])) ?? []
    }

    static func packageURLs(root: URL, extensionName: String, context: DomainScanContext) -> [URL] {
        guard let enumerator = context.fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isDirectoryKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true })
        else {
            return []
        }

        var matches: [URL] = []
        for case let url as URL in enumerator {
            if Task.isCancelled {
                enumerator.skipDescendants()
                break
            }
            if url.pathExtension.lowercased() == extensionName.lowercased() {
                matches.append(url)
                enumerator.skipDescendants()
            }
        }
        return matches
    }

    static func missingOrUnreadableRoot(_ root: URL, context: DomainScanContext, result: inout DomainScanResult) -> Bool {
        let path = root.standardizedFileURL.path
        guard context.configuration.isExcluded(path) == false else {
            return true
        }

        var isDirectory: ObjCBool = false
        guard context.fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            result.missingPaths.append(path)
            return true
        }
        return false
    }

    static func ageDays(since date: Date?, now: Date) -> Int? {
        guard let date else {
            return nil
        }
        return max(0, Int(now.timeIntervalSince(date) / 86_400))
    }

    static func state(ageDays: Int?, staleThreshold: Int) -> String {
        guard let ageDays else {
            return "Unknown"
        }
        return ageDays >= staleThreshold ? "Stale" : "Recent"
    }
}
