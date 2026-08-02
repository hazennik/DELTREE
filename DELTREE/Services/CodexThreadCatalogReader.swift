import Foundation

struct CodexThreadCatalogReader: CodexSessionScanning, @unchecked Sendable {
    private let homeDirectory: URL
    private let fileManager: FileManager
    private let maximumFiles: Int
    private let maximumBytesPerFile: UInt64

    init(
        homeDirectory: URL = FileManager.default.homeDirectoryForCurrentUser,
        fileManager: FileManager = .default,
        maximumFiles: Int = 2_000,
        maximumBytesPerFile: UInt64 = 5_000_000)
    {
        self.homeDirectory = homeDirectory
        self.fileManager = fileManager
        self.maximumFiles = maximumFiles
        self.maximumBytesPerFile = maximumBytesPerFile
    }

    nonisolated func sessions(now: Date) async -> [CodexSessionRecord] {
        await Task.detached(priority: .utility) {
            scanSessions(now: now)
        }.value
    }

    nonisolated private func scanSessions(now: Date) -> [CodexSessionRecord] {
        let roots = [
            homeDirectory.appendingPathComponent(".codex/sessions", isDirectory: true),
            homeDirectory.appendingPathComponent(".codex/tasks", isDirectory: true),
            homeDirectory.appendingPathComponent(".codex/history.jsonl"),
        ]

        let candidateFiles = roots.flatMap { candidateSessionFiles(under: $0) }
            .sorted { lhs, rhs in
                modificationDate(for: lhs) > modificationDate(for: rhs)
            }
            .prefix(maximumFiles)

        var recordsByID: [String: CodexSessionRecord] = [:]
        for file in candidateFiles {
            for record in parse(file: file, now: now) {
                let current = recordsByID[record.id]
                if current == nil || (record.lastUpdatedAt ?? .distantPast) > (current?.lastUpdatedAt ?? .distantPast) {
                    recordsByID[record.id] = record
                }
            }
        }

        return recordsByID.values.sorted {
            ($0.lastUpdatedAt ?? .distantPast) > ($1.lastUpdatedAt ?? .distantPast)
        }
    }

    nonisolated private func candidateSessionFiles(under root: URL) -> [URL] {
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: root.path, isDirectory: &isDirectory) else {
            return []
        }

        if isDirectory.boolValue == false {
            return isSupportedFile(root) ? [root] : []
        }

        guard let enumerator = fileManager.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey, .fileSizeKey, .contentModificationDateKey],
            options: [.skipsHiddenFiles, .skipsPackageDescendants],
            errorHandler: { _, _ in true })
        else {
            return []
        }

        var files: [URL] = []
        for case let url as URL in enumerator {
            if Task.isCancelled {
                break
            }
            guard isSupportedFile(url),
                  let values = try? url.resourceValues(forKeys: [.isRegularFileKey, .fileSizeKey]),
                  values.isRegularFile == true,
                  UInt64(values.fileSize ?? 0) <= maximumBytesPerFile
            else {
                continue
            }
            files.append(url)
            if files.count >= maximumFiles {
                break
            }
        }
        return files
    }

    nonisolated private func isSupportedFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ext == "jsonl" || ext == "json" || ext == "md" || ext == "txt"
    }

    nonisolated private func parse(file: URL, now: Date) -> [CodexSessionRecord] {
        guard let data = try? Data(contentsOf: file),
              data.isEmpty == false,
              let text = String(data: data, encoding: .utf8)
        else {
            return []
        }

        let parsedRecords = text
            .split(separator: "\n", omittingEmptySubsequences: true)
            .prefix(400)
            .compactMap { line -> CodexSessionRecord? in
                parseJSONLine(String(line), sourcePath: file.path, fallbackDate: modificationDate(for: file))
            }

        if parsedRecords.isEmpty == false {
            return Array(parsedRecords)
        }

        let title = firstUsefulLine(in: text) ?? file.deletingPathExtension().lastPathComponent
        return [
            CodexSessionRecord(
                id: file.deletingPathExtension().lastPathComponent,
                title: title,
                workingDirectory: extractLikelyPath(from: text),
                sourcePath: file.path,
                startedAt: nil,
                lastUpdatedAt: modificationDate(for: file)),
        ]
    }

    nonisolated private func parseJSONLine(_ line: String, sourcePath: String, fallbackDate: Date?) -> CodexSessionRecord? {
        guard let data = line.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        let flattened = flatten(object)
        let id = firstString(
            in: flattened,
            keys: ["id", "session_id", "sessionId", "thread_id", "threadId", "conversation_id", "conversationId"])
        let title = firstString(
            in: flattened,
            keys: ["title", "name", "objective", "summary", "prompt"])
        let workingDirectory = firstString(
            in: flattened,
            keys: ["cwd", "workdir", "working_directory", "workingDirectory", "workspace", "path"])
        let dateString = firstString(
            in: flattened,
            keys: ["created_at", "createdAt", "updated_at", "updatedAt", "timestamp", "time"])

        guard id != nil || title != nil || workingDirectory != nil else {
            return nil
        }

        return CodexSessionRecord(
            id: id ?? URL(fileURLWithPath: sourcePath).deletingPathExtension().lastPathComponent,
            title: title ?? URL(fileURLWithPath: sourcePath).deletingPathExtension().lastPathComponent,
            workingDirectory: workingDirectory,
            sourcePath: sourcePath,
            startedAt: FlexibleCodexDateParser.date(from: dateString),
            lastUpdatedAt: FlexibleCodexDateParser.date(from: dateString) ?? fallbackDate)
    }

    nonisolated private func flatten(_ object: [String: Any]) -> [String: [String]] {
        var values: [String: [String]] = [:]
        collect(object, into: &values)
        return values
    }

    nonisolated private func collect(_ object: Any, into values: inout [String: [String]]) {
        if let dictionary = object as? [String: Any] {
            for (key, value) in dictionary {
                if let string = value as? String, string.isEmpty == false {
                    values[key, default: []].append(string)
                } else {
                    collect(value, into: &values)
                }
            }
        } else if let array = object as? [Any] {
            for value in array {
                collect(value, into: &values)
            }
        }
    }

    nonisolated private func firstString(in values: [String: [String]], keys: [String]) -> String? {
        for key in keys {
            if let value = values[key]?.first, value.isEmpty == false {
                return value
            }
        }
        return nil
    }

    nonisolated private func firstUsefulLine(in text: String) -> String? {
        text.split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .first { line in
                line.count >= 4 && line.count <= 140 && line.hasPrefix("{") == false
            }
    }

    nonisolated private func extractLikelyPath(from text: String) -> String? {
        text.split(whereSeparator: \.isWhitespace)
            .map(String.init)
            .first { token in
                token.hasPrefix("/") && token.count > 5
            }
    }

    nonisolated private func modificationDate(for url: URL) -> Date {
        (try? url.resourceValues(forKeys: [.contentModificationDateKey]).contentModificationDate) ?? .distantPast
    }
}

private enum FlexibleCodexDateParser {
    nonisolated static func date(from string: String?) -> Date? {
        guard let string, string.isEmpty == false else {
            return nil
        }

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: string) {
            return date
        }

        formatter.formatOptions = [.withInternetDateTime]
        return formatter.date(from: string)
    }
}
