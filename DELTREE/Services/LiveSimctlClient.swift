import Foundation

struct LiveSimctlClient: SimctlClient {
    func devices() async -> [SimctlDevice] {
        await Task.detached(priority: .utility) {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
            process.arguments = ["simctl", "list", "devices", "--json"]

            let output = Pipe()
            let errorOutput = Pipe()
            process.standardOutput = output
            process.standardError = errorOutput

            do {
                try process.run()
                process.waitUntilExit()
                guard process.terminationStatus == 0 else {
                    return []
                }
                let data = output.fileHandleForReading.readDataToEndOfFile()
                return (try? SimctlDeviceParser.parse(data: data)) ?? []
            } catch {
                return []
            }
        }.value
    }
}
