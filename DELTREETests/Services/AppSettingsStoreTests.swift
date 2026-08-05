import Foundation
import Testing
@testable import DELTREE

@MainActor
struct AppSettingsStoreTests {
    @Test func visualModeDefaultsToClassic() throws {
        let defaults = try Self.makeDefaults()

        let store = AppSettingsStore(defaults: defaults)

        #expect(store.visualMode == .classic)
    }

    @Test func visualModePersistsModernSelection() throws {
        let defaults = try Self.makeDefaults()
        let store = AppSettingsStore(defaults: defaults)

        store.visualMode = .modern
        let restored = AppSettingsStore(defaults: defaults)

        #expect(restored.visualMode == .modern)
    }

    @Test func unknownVisualModeFallsBackToClassic() throws {
        let defaults = try Self.makeDefaults()
        defaults.set("unknown-mode", forKey: "visualMode")

        let store = AppSettingsStore(defaults: defaults)

        #expect(store.visualMode == .classic)
    }

    @Test func visualModeDoesNotTriggerScanSettingsChangeToken() throws {
        let defaults = try Self.makeDefaults()
        let store = AppSettingsStore(defaults: defaults)
        let before = store.changeToken

        store.visualMode = .modern

        #expect(store.changeToken == before)
    }

    @Test func visualModeChangeCallsAppearanceHandler() throws {
        let defaults = try Self.makeDefaults()
        let store = AppSettingsStore(defaults: defaults)
        var changeCount = 0
        store.onAppearanceChange = {
            changeCount += 1
        }

        store.visualMode = .modern
        store.visualMode = .modern

        #expect(changeCount == 1)
    }

    private static func makeDefaults() throws -> UserDefaults {
        let suiteName = "deltree-settings-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
