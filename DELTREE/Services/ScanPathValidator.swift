import Foundation

enum ScanPathValidationError: LocalizedError, Equatable {
    case relativePath
    case protectedRoot(String)
    case overlappingPath(String)

    var errorDescription: String? {
        switch self {
        case .relativePath:
            "Choose an absolute path."
        case let .protectedRoot(path):
            "\(path) is too broad to use as a scan root or exclusion."
        case let .overlappingPath(path):
            "\(path) overlaps a path that is already configured."
        }
    }
}

enum ScanPathValidator {
    private static let protectedRoots: Set<String> = [
        "/",
        "/Applications",
        "/Library",
        "/System",
        "/Users",
        "/Volumes",
    ]

    static func validatedPath(
        _ path: String,
        existingPaths: [String] = [],
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) throws -> String
    {
        let trimmedPath = path.trimmingCharacters(in: .whitespacesAndNewlines)
        let expandedPath = (trimmedPath as NSString).expandingTildeInPath
        guard (expandedPath as NSString).isAbsolutePath else {
            throw ScanPathValidationError.relativePath
        }

        let standardizedPath = URL(fileURLWithPath: expandedPath)
            .standardizedFileURL
            .resolvingSymlinksInPath()
            .path
        let standardizedHome = homeDirectory.standardizedFileURL.resolvingSymlinksInPath().path
        guard protectedRoots.contains(standardizedPath) == false,
              standardizedPath != standardizedHome
        else {
            throw ScanPathValidationError.protectedRoot(standardizedPath)
        }

        let normalizedExistingPaths = existingPaths.compactMap {
            try? validatedPath($0, homeDirectory: homeDirectory)
        }
        if normalizedExistingPaths.contains(where: { existingPath in
            existingPath == standardizedPath ||
                existingPath.hasPrefix(standardizedPath + "/") ||
                standardizedPath.hasPrefix(existingPath + "/")
        }) {
            throw ScanPathValidationError.overlappingPath(standardizedPath)
        }

        return standardizedPath
    }

    static func validatedPaths(
        from text: String,
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser) -> [String]
    {
        var validated: [String] = []
        for line in text.split(whereSeparator: \.isNewline) {
            guard let path = try? validatedPath(
                String(line),
                existingPaths: validated,
                homeDirectory: homeDirectory)
            else {
                continue
            }
            validated.append(path)
        }
        return validated
    }
}
