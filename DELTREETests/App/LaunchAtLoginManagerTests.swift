import ServiceManagement
import Testing
@testable import DELTREE

struct LaunchAtLoginManagerTests {
    @Test func enabledRegistersOnlyWhenNeeded() {
        var registerCalls = 0
        var unregisterCalls = 0

        LaunchAtLoginManager.setEnabled(
            true,
            status: { .notRegistered },
            register: { registerCalls += 1 },
            unregister: { unregisterCalls += 1 })

        #expect(registerCalls == 1)
        #expect(unregisterCalls == 0)
    }

    @Test func enabledDoesNotRegisterWhenApprovalIsPending() {
        var registerCalls = 0

        LaunchAtLoginManager.setEnabled(
            true,
            status: { .requiresApproval },
            register: { registerCalls += 1 },
            unregister: {})

        #expect(registerCalls == 0)
    }

    @Test func disabledUnregistersEnabledService() {
        var unregisterCalls = 0

        LaunchAtLoginManager.setEnabled(
            false,
            status: { .enabled },
            register: {},
            unregister: { unregisterCalls += 1 })

        #expect(unregisterCalls == 1)
    }

    @Test func disabledLeavesUnregisteredServiceAlone() {
        var unregisterCalls = 0

        LaunchAtLoginManager.setEnabled(
            false,
            status: { .notRegistered },
            register: {},
            unregister: { unregisterCalls += 1 })

        #expect(unregisterCalls == 0)
    }
}
