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
        await Task.detached(priority: .utility) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/bin/ps")
            process.arguments = ["-axo", "pid=,comm=,args="]

            let output = Pipe()
            process.standardOutput = output
            process.standardError = Pipe()

            do {
                try process.run()
                process.waitUntilExit()
                let data = output.fileHandleForReading.readDataToEndOfFile()
                let text = String(decoding: data, as: UTF8.self)
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
        }.value
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
