import Foundation
import Testing
@testable import DELTREE

@MainActor
struct DashboardViewModelPresentationTests {
    @Test func menuBarTitleUsesTheHighestPriorityVisibleState() {
        let viewModel = DashboardViewModel.preview
        viewModel.snapshot = snapshot([
            item(id: "safe", bytes: 2_000_000, safety: .safeToTrash),
        ])

        viewModel.isScanning = true
        #expect(viewModel.menuBarTitle == "Scanning...")

        viewModel.isScanning = false
        viewModel.settings.lowDiskThresholdGB = 1
        viewModel.availableDiskBytes = 500_000_000
        #expect(viewModel.menuBarTitle.hasPrefix("Disk Low:"))

        viewModel.availableDiskBytes = 2_000_000_000
        viewModel.settings.recentGrowthThresholdGB = 0.001
        viewModel.lastDelta = delta(growthBytes: 2_000_000)
        #expect(viewModel.menuBarTitle.hasPrefix("+"))

        viewModel.lastDelta = .empty
        #expect(viewModel.menuBarTitle.hasPrefix("Reclaimable:"))

        viewModel.snapshot = snapshot([
            item(id: "kept", bytes: 2_000_000, safety: .keep),
        ])
        #expect(viewModel.menuBarTitle.hasPrefix("DELTREE:"))
    }

    @Test func domainSummariesSortByBytesAndCountItems() {
        let viewModel = DashboardViewModel.preview
        viewModel.snapshot = snapshot([
            item(id: "derived-a", domain: .derivedData, bytes: 300),
            item(id: "derived-b", domain: .derivedData, bytes: 200),
            item(id: "result", domain: .xcResults, bytes: 800),
        ])

        #expect(viewModel.domainSummaries.map(\.domain) == [.xcResults, .derivedData])
        #expect(viewModel.domainSummaries.map(\.bytes) == [800, 500])
        #expect(viewModel.domainSummaries.map(\.itemCount) == [1, 2])
    }

    @Test func sectionAndExplicitFiltersCompose() {
        let viewModel = DashboardViewModel.preview
        viewModel.snapshot = snapshot([
            item(
                id: "matching",
                domain: .derivedData,
                displayName: "Checkout Build",
                bytes: 300,
                attribution: .xcode,
                safety: .reviewRecommended),
            item(
                id: "wrong-owner",
                domain: .derivedData,
                displayName: "Checkout Codex Build",
                bytes: 400,
                attribution: .codex,
                safety: .reviewRecommended),
            item(
                id: "wrong-section",
                domain: .xcResults,
                displayName: "Checkout Results",
                bytes: 500,
                attribution: .xcode,
                safety: .reviewRecommended),
        ])
        viewModel.selectedSection = .buildArtifacts
        viewModel.selectedSafety = .reviewRecommended
        viewModel.selectedOwner = .xcode
        viewModel.searchText = "checkout"

        #expect(viewModel.filteredItems.map(\.id) == ["matching"])
    }

    @Test func explicitDomainSelectionOverridesTheSectionGrouping() {
        let viewModel = DashboardViewModel.preview
        viewModel.snapshot = snapshot([
            item(id: "derived", domain: .derivedData, bytes: 100),
            item(id: "result", domain: .xcResults, bytes: 200),
        ])
        viewModel.selectedSection = .buildArtifacts
        viewModel.selectedDomain = .xcResults

        #expect(viewModel.filteredItems.map(\.id) == ["result"])
    }

    @Test func searchMatchesProjectAndCodexTaskMetadata() {
        let viewModel = DashboardViewModel.preview
        viewModel.snapshot = snapshot([
            item(
                id: "project",
                bytes: 100,
                metadata: ["relatedProject": "Storefront"]),
            item(
                id: "task",
                bytes: 200,
                metadata: ["codexTaskTitle": "Repair checkout tests"]),
        ])

        viewModel.searchText = "storefront"
        #expect(viewModel.filteredItems.map(\.id) == ["project"])

        viewModel.searchText = "checkout"
        #expect(viewModel.filteredItems.map(\.id) == ["task"])
    }

    @Test func ignoredItemsAreHiddenUntilRequested() {
        let viewModel = DashboardViewModel.preview
        viewModel.snapshot = snapshot([
            item(id: "visible", bytes: 100),
            item(id: "ignored", bytes: 200, isIgnored: true),
        ])

        #expect(viewModel.filteredItems.map(\.id) == ["visible"])

        viewModel.includeIgnoredItems = true
        #expect(viewModel.filteredItems.map(\.id) == ["ignored", "visible"])
    }

    @Test func selectedItemNeverShowsAnItemHiddenByTheCurrentFilters() {
        let viewModel = DashboardViewModel.preview
        viewModel.snapshot = snapshot([
            item(id: "visible", bytes: 100, safety: .safeToTrash),
            item(id: "hidden", bytes: 200, safety: .keep),
        ])
        viewModel.selectedItemID = "hidden"
        viewModel.selectedSafety = .safeToTrash

        #expect(viewModel.filteredItems.map(\.id) == ["visible"])
        #expect(viewModel.selectedItem?.id == "visible")
    }

    @Test func selectedItemIsNilWhenNoItemsAreVisible() {
        let viewModel = DashboardViewModel.preview
        viewModel.snapshot = snapshot([
            item(id: "kept", bytes: 100, safety: .keep),
        ])
        viewModel.selectedItemID = "kept"
        viewModel.selectedSafety = .safeToTrash

        #expect(viewModel.filteredItems.isEmpty)
        #expect(viewModel.selectedItem == nil)
    }

    @Test func showReviewItemClearsFiltersAndSelectsRequestedItem() {
        let viewModel = DashboardViewModel.preview
        viewModel.snapshot = snapshot([
            item(id: "review", domain: .derivedData, bytes: 300, safety: .probablySafe),
            item(id: "other", domain: .xcResults, bytes: 100, safety: .safeToTrash),
        ])
        viewModel.searchText = "missing"
        viewModel.selectedSection = .testArtifacts
        viewModel.selectedDomain = .xcResults
        viewModel.selectedSafety = .safeToTrash
        viewModel.selectedOwner = .codex
        viewModel.includeIgnoredItems = true
        viewModel.selectedItemID = "other"

        viewModel.showReviewItem(id: "review")

        #expect(viewModel.searchText.isEmpty)
        #expect(viewModel.selectedSection == .overview)
        #expect(viewModel.selectedDomain == nil)
        #expect(viewModel.selectedSafety == nil)
        #expect(viewModel.selectedOwner == nil)
        #expect(viewModel.includeIgnoredItems == false)
        #expect(viewModel.selectedItem?.id == "review")
    }

    private func snapshot(_ items: [StorageItem]) -> StorageSnapshot {
        StorageSnapshot(
            capturedAt: Date(timeIntervalSince1970: 1_788_048_000),
            items: items,
            missingPaths: [],
            unreadablePaths: [])
    }

    private func item(
        id: String,
        domain: StorageDomain = .derivedData,
        displayName: String? = nil,
        bytes: Int64,
        attribution: OwnerAttribution = .xcode,
        safety: SafetyClassification = .reviewRecommended,
        isIgnored: Bool = false,
        metadata: [String: String] = [:])
        -> StorageItem
    {
        StorageItem(
            id: id,
            domain: domain,
            kind: .derivedData,
            path: "/tmp/\(id)",
            displayName: displayName ?? id,
            bytes: bytes,
            createdAt: nil,
            modifiedAt: nil,
            lastUsedAt: nil,
            attribution: attribution,
            attributionConfidence: 0.8,
            safety: safety,
            isActive: false,
            isIgnored: isIgnored,
            explanation: "Test fixture",
            metadata: metadata)
    }

    private func delta(growthBytes: Int64) -> StorageDelta {
        StorageDelta(
            fromDate: nil,
            toDate: Date(timeIntervalSince1970: 1_788_048_000),
            addedBytes: growthBytes,
            changedBytes: 0,
            removedBytes: 0,
            newItems: [],
            changedItems: [],
            removedPaths: [])
    }
}
