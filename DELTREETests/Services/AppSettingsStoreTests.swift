import Foundation
import Testing
@testable import DELTREE

@MainActor
struct AppSettingsStoreTests {
    @Test func visualModeDefaultsToModern() throws {
        let defaults = try Self.makeDefaults()

        let store = AppSettingsStore(defaults: defaults)

        #expect(store.visualMode == .modern)
    }

    @Test func visualModePersistsClassicSelection() throws {
        let defaults = try Self.makeDefaults()
        let store = AppSettingsStore(defaults: defaults)

        store.visualMode = .classic
        let restored = AppSettingsStore(defaults: defaults)

        #expect(restored.visualMode == .classic)
    }

    @Test func unknownVisualModeFallsBackToModern() throws {
        let defaults = try Self.makeDefaults()
        defaults.set("unknown-mode", forKey: "visualMode")

        let store = AppSettingsStore(defaults: defaults)

        #expect(store.visualMode == .modern)
    }

    @Test func visualModeDoesNotTriggerScanSettingsChangeToken() throws {
        let defaults = try Self.makeDefaults()
        let store = AppSettingsStore(defaults: defaults)
        let before = store.changeToken

        store.visualMode = .classic

        #expect(store.changeToken == before)
    }

    @Test func visualModeChangeCallsAppearanceHandler() throws {
        let defaults = try Self.makeDefaults()
        let store = AppSettingsStore(defaults: defaults)
        var changeCount = 0
        store.onAppearanceChange = {
            changeCount += 1
        }

        store.visualMode = .classic
        store.visualMode = .classic

        #expect(changeCount == 1)
    }

    @Test func documentsCodexAccessDefaultsOffAndPersistsOptIn() throws {
        let defaults = try Self.makeDefaults()
        let store = AppSettingsStore(defaults: defaults)

        #expect(store.scanDocumentsCodex == false)

        store.scanDocumentsCodex = true
        store.documentsCodexAccessVerified = true
        let restored = AppSettingsStore(defaults: defaults)

        #expect(restored.scanDocumentsCodex)
        #expect(restored.documentsCodexAccessVerified)
        #expect(restored.scanConfiguration.scanDocumentsCodex)
    }

    @Test func scanConfigurationDropsInvalidAndOverlappingPersistedPaths() throws {
        let defaults = try Self.makeDefaults()
        defaults.set("relative/path\n/\n/tmp/project\n/tmp/project/nested", forKey: "customScanRootsText")
        defaults.set("/System\n/tmp/excluded", forKey: "excludedPathsText")

        let configuration = AppSettingsStore(defaults: defaults).scanConfiguration

        #expect(configuration.customScanRoots == ["/tmp/project"])
        #expect(configuration.excludedPaths == ["/tmp/excluded"])
    }

    @Test func launchAtLoginDefaultsOffAndPersists() throws {
        let defaults = try Self.makeDefaults()
        let store = AppSettingsStore(defaults: defaults)

        #expect(store.launchAtLogin == false)

        store.launchAtLogin = true
        #expect(AppSettingsStore(defaults: defaults).launchAtLogin)
    }

    private static func makeDefaults() throws -> UserDefaults {
        let suiteName = "deltree-settings-\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        return defaults
    }
}
