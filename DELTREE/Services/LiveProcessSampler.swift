import Foundation

struct LiveProcessSampler: ProcessSampling {
    private let watchedTerms = [
        "codex",
        "xcodebuild",
        "simctl",
        "Simulator",
        "CoreSimulatorService",
    ]

    func sample() async -> ProcessSnapshot {
        do {
            let output = try await ProcessRunner.run(
                executableURL: URL(fileURLWithPath: "/bin/ps"),
                arguments: ["-axo", "pid=,comm=,args="],
                timeoutSeconds: 3)
            guard output.terminationStatus == 0 else {
                return ProcessSnapshot(sampledAt: Date(), processes: [])
            }
            let text = String(decoding: output.stdout, as: UTF8.self)
            return ProcessSnapshot(
                sampledAt: Date(),
                processes: parse(text: text).filter { observed in
                    watchedTerms.contains { term in
                        observed.command.localizedCaseInsensitiveContains(term) ||
                            observed.arguments.localizedCaseInsensitiveContains(term)
                    }
                })
        } catch {
            return ProcessSnapshot(sampledAt: Date(), processes: [])
        }
    }

    nonisolated private func parse(text: String) -> [ObservedProcess] {
        text.split(separator: "\n").compactMap { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            guard trimmed.isEmpty == false else {
                return nil
            }

            let parts = trimmed.split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
            guard parts.count >= 2, let pid = Int32(parts[0]) else {
                return nil
            }

            return ObservedProcess(
                pid: pid,
                command: String(parts[1]),
                arguments: parts.count == 3 ? String(parts[2]) : "")
        }
    }
}

struct LiveLsofOpenFileChecker: OpenFileChecking, @unchecked Sendable {
    private let fileManager: FileManager
    private let lsofURL: URL

    init(
        fileManager: FileManager = .default,
        lsofURL: URL = URL(fileURLWithPath: "/usr/sbin/lsof"))
    {
        self.fileManager = fileManager
        self.lsofURL = lsofURL
    }

    func checkOpenFiles(under url: URL) async -> OpenFileCheckResult {
        let path = url.standardizedFileURL.path
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: path, isDirectory: &isDirectory) else {
            return .unavailable("Path no longer exists.")
        }

        var arguments = ["-nP", "-F", "p"]
        if isDirectory.boolValue {
            arguments.append(contentsOf: ["+D", path])
        } else {
            arguments.append(path)
        }

        do {
            let output = try await ProcessRunner.run(
                executableURL: lsofURL,
                arguments: arguments,
                timeoutSeconds: 5)
            let stdout = String(decoding: output.stdout, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let stderr = String(decoding: output.stderr, as: UTF8.self)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            if stdout.isEmpty == false {
                return .openFilesFound
            }

            if output.terminationStatus == 1, stderr.isEmpty {
                return .clear
            }

            if output.terminationStatus == 0 {
                return .clear
            }

            return .unavailable(stderr.isEmpty ? "lsof exited with status \(output.terminationStatus)." : stderr)
        } catch {
            return .unavailable(error.localizedDescription)
        }
    }
}
