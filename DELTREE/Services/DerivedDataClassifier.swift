import Foundation

struct DerivedDataClassifier {
    func metadata(for url: URL, context: DomainScanContext) -> [String: String] {
        let displayName = url.lastPathComponent
        var metadata: [String: String] = [
            "suggestedAction": StorageAction.cleanDerivedData.rawValue,
            "relatedProject": projectName(from: displayName),
        ]

        if let ageDays = DirectoryScannerHelpers.ageDays(
            since: FileMetadataReader.metadata(for: url).modifiedAt,
            now: context.now)
        {
            metadata["ageDays"] = "\(ageDays)"
            metadata["state"] = DirectoryScannerHelpers.state(ageDays: ageDays, staleThreshold: context.configuration.staleAgeDays)
        }

        if let packagePath = firstDescendant(
            under: url.appendingPathComponent("SourcePackages", isDirectory: true),
            extensions: ["resolved", "swift"],
            context: context)
        {
            metadata["packageSignal"] = packagePath.lastPathComponent
        }

        metadata.merge(CodexSessionMatcher.metadata(for: url.path, sessions: context.codexSessions)) { current, _ in current }
        return metadata
    }

    private func projectName(from folderName: String) -> String {
        let parts = folderName.split(separator: "-")
        guard parts.count > 1 else {
            return folderName
        }
        return parts.dropLast().joined(separator: "-")
    }

    private func firstDescendant(under root: URL, extensions: Set<String>, context: DomainScanContext) -> URL? {
        guard let enumerator = context.fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles],
            errorHandler: { _, _ in true })
        else {
            return nil
        }

        for case let url as URL in enumerator {
            if Task.isCancelled {
                enumerator.skipDescendants()
                break
            }

            if extensions.contains(url.pathExtension.lowercased()) {
                return url
            }
        }
        return nil
    }
}
