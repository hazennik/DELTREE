import Foundation

struct SimctlDevice: Hashable, Sendable {
    var udid: String
    var name: String
    var state: String
    var isAvailable: Bool
    var availabilityError: String?
    var runtimeIdentifier: String
    var dataPath: String?
    var logPath: String?
    var lastBootedAt: Date?

    var isBooted: Bool {
        state.localizedCaseInsensitiveContains("booted")
    }
}
