import Foundation
import OSLog
import ServiceManagement

enum LaunchAtLoginManager {
    typealias StatusProvider = () -> SMAppService.Status
    typealias RegistrationAction = () throws -> Void

    private static let logger = Logger(subsystem: "com.Infrallabs.DELTREE", category: "launch-at-login")
    private static let isRunningTests: Bool = {
        let environment = ProcessInfo.processInfo.environment
        return environment["XCTestConfigurationFilePath"] != nil ||
            environment["TESTING_LIBRARY_VERSION"] != nil ||
            environment["SWIFT_TESTING"] != nil ||
            NSClassFromString("XCTestCase") != nil
    }()

    static func setEnabled(_ enabled: Bool) {
        guard isRunningTests == false else {
            return
        }
        let service = SMAppService.mainApp
        setEnabled(
            enabled,
            status: { service.status },
            register: { try service.register() },
            unregister: { try service.unregister() })
    }

    static func setEnabled(
        _ enabled: Bool,
        status: StatusProvider,
        register: RegistrationAction,
        unregister: RegistrationAction)
    {
        do {
            if enabled {
                switch status() {
                case .enabled, .requiresApproval:
                    return
                case .notRegistered, .notFound:
                    try register()
                @unknown default:
                    try register()
                }
            } else {
                switch status() {
                case .enabled, .requiresApproval:
                    try unregister()
                case .notRegistered, .notFound:
                    return
                @unknown default:
                    try unregister()
                }
            }
        } catch {
            logger.error("Failed to update login item: \(error.localizedDescription, privacy: .public)")
        }
    }
}
