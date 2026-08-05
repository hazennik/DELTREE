import Testing
@testable import DELTREE

struct AppThemeTests {
    @Test func classicBlockMeterUsesTerminalBlocks() {
        let meter = AppTheme.classic.blockMeter(share: 0.62, width: 10)

        #expect(meter == "██████░░░░ 62%")
    }

    @Test func blockMeterClampsShare() {
        #expect(AppTheme.classic.blockMeter(share: 2, width: 4) == "████ 100%")
        #expect(AppTheme.classic.blockMeter(share: -1, width: 4) == "░░░░ 0%")
    }

    @Test func classicSafetyLabelsAreExplicit() {
        let theme = AppTheme.classic

        #expect(theme.safetyTitle(.safeToTrash, isActive: false) == "[SAFE]")
        #expect(theme.safetyTitle(.reviewRecommended, isActive: false) == "[REVIEW]")
        #expect(theme.safetyTitle(.keep, isActive: false) == "[KEEP]")
        #expect(theme.safetyTitle(.unknown, isActive: false) == "[UNKNOWN]")
    }

    @Test func modernSafetyLabelsPreserveExistingText() {
        let theme = AppTheme.modern

        #expect(theme.safetyTitle(.safeToTrash, isActive: false) == SafetyClassification.safeToTrash.displayName)
        #expect(theme.safetyTitle(.unknown, isActive: false) == SafetyClassification.unknown.displayName)
    }
}
