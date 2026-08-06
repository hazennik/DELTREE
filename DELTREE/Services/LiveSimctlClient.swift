import Foundation

struct LiveSimctlClient: SimctlClient {
    func devices() async -> [SimctlDevice] {
        do {
            let output = try await ProcessRunner.run(
                executableURL: URL(fileURLWithPath: "/usr/bin/xcrun"),
                arguments: ["simctl", "list", "devices", "--json"],
                timeoutSeconds: 8)
            guard output.terminationStatus == 0 else {
                return []
            }
            return (try? SimctlDeviceParser.parse(data: output.stdout)) ?? []
        } catch {
            return []
        }
    }
}
