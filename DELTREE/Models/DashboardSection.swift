import Foundation

enum DashboardSection: String, CaseIterable, Identifiable, Codable, Sendable {
    case overview
    case simulators
    case buildArtifacts
    case testArtifacts
    case runtimesComponents
    case codexTasks
    case cleanupHistory
    case rules

    var id: String { rawValue }

    nonisolated var displayName: String {
        switch self {
        case .overview:
            "Overview"
        case .simulators:
            "Simulators"
        case .buildArtifacts:
            "Build Artifacts"
        case .testArtifacts:
            "Test Artifacts"
        case .runtimesComponents:
            "Runtimes & Components"
        case .codexTasks:
            "Codex Tasks"
        case .cleanupHistory:
            "Cleanup History"
        case .rules:
            "Rules"
        }
    }

    nonisolated var symbolName: String {
        switch self {
        case .overview:
            "chart.pie"
        case .simulators:
            "iphone"
        case .buildArtifacts:
            "hammer"
        case .testArtifacts:
            "checklist"
        case .runtimesComponents:
            "square.stack.3d.up"
        case .codexTasks:
            "terminal"
        case .cleanupHistory:
            "clock.arrow.circlepath"
        case .rules:
            "slider.horizontal.3"
        }
    }

    nonisolated var domains: Set<StorageDomain>? {
        switch self {
        case .overview, .cleanupHistory, .rules:
            nil
        case .simulators:
            [.coreSimulatorDevices, .xcTestDevices]
        case .buildArtifacts:
            [.derivedData, .xcodeProducts, .swiftPackageCaches, .coreSimulatorCaches]
        case .testArtifacts:
            [.xcResults]
        case .runtimesComponents:
            [.simulatorRuntimes, .simulatorImages, .deviceSupport, .archives]
        case .codexTasks:
            [.codexHome, .codexWorkspaces]
        }
    }
}
