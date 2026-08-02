import Foundation
import Testing
@testable import DELTREE

struct SafetyPolicyTests {
    private let policy = DefaultSafetyPolicy()

    @Test func activeSimulatorIsKept() {
        var item = Self.item(domain: .coreSimulatorDevices, kind: .simulatorDevice)
        item.isActive = true

        let decision = policy.classify(item: item, configuration: .standard, now: Date())

        #expect(decision.classification == .keep)
    }

    @Test func archivesAndRuntimesAreNotOneClickSafe() {
        let archive = Self.item(domain: .archives, kind: .archive)
        let runtime = Self.item(domain: .simulatorRuntimes, kind: .simulatorRuntime)

        #expect(policy.classify(item: archive, configuration: .standard, now: Date()).classification == .reviewRecommended)
        #expect(policy.classify(item: runtime, configuration: .standard, now: Date()).classification == .keep)
    }

    @Test func staleCodexAttributedXCTestDeviceIsSafe() {
        var item = Self.item(domain: .xcTestDevices, kind: .xcTestDevice)
        item.attribution = .xcodeViaCodex
        item.lastUsedAt = Date().addingTimeInterval(-30 * 86_400)

        let decision = policy.classify(item: item, configuration: .standard, now: Date())

        #expect(decision.classification == .safeToTrash)
    }

    @Test func keepLastTestRunsProtectsResultBundles() {
        var item = Self.item(domain: .xcResults, kind: .xcResult)
        item.attribution = .xcodeViaCodex
        item.metadata["protectedByKeepLastTestRuns"] = "true"

        let decision = policy.classify(item: item, configuration: .standard, now: Date())

        #expect(decision.classification == .reviewRecommended)
        #expect(decision.reason.contains("keep-last-test-runs"))
    }

    @Test func pinnedAndIgnoredItemsAreKept() {
        var pinned = Self.item(domain: .derivedData, kind: .derivedData)
        pinned.isPinned = true
        var ignored = Self.item(domain: .xcResults, kind: .xcResult)
        ignored.isIgnored = true

        #expect(policy.classify(item: pinned, configuration: .standard, now: Date()).classification == .keep)
        #expect(policy.classify(item: ignored, configuration: .standard, now: Date()).classification == .keep)
    }

    private static func item(domain: StorageDomain, kind: StorageKind) -> StorageItem {
        StorageItem(
            id: UUID().uuidString,
            domain: domain,
            kind: kind,
            path: "/tmp/\(UUID().uuidString)",
            displayName: "Fixture",
            bytes: 1_024,
            createdAt: Date().addingTimeInterval(-30 * 86_400),
            modifiedAt: Date().addingTimeInterval(-30 * 86_400),
            lastUsedAt: Date().addingTimeInterval(-30 * 86_400),
            attribution: .xcode,
            attributionConfidence: 0.5,
            safety: .unknown,
            isActive: false,
            explanation: "Fixture",
            metadata: [:])
    }
}
