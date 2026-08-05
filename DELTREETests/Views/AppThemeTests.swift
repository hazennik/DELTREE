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

    @Test func classicNormalStorageTintsUseNeutralText() {
        let theme = AppTheme.classic

        #expect(theme.safe == theme.normalTint)
        #expect(theme.keep == theme.normalTint)
        #expect(theme.unknown == theme.normalTint)
        #expect(theme.safetyTint(.safeToTrash, isActive: false) == theme.normalTint)
        #expect(theme.safetyTint(.keep, isActive: false) == theme.normalTint)
        #expect(theme.safetyTint(.unknown, isActive: false) == theme.normalTint)
        #expect(theme.safetyTint(.safeToTrash, isActive: true) == theme.normalTint)

        for domain in StorageDomain.allCases {
            #expect(theme.domainTint(domain) == theme.normalTint)
        }
    }

    @Test func classicRiskStorageTintsUseWarningColor() {
        let theme = AppTheme.classic

        #expect(theme.review == theme.warning)
        #expect(theme.safetyTint(.probablySafe, isActive: false) == theme.warning)
        #expect(theme.safetyTint(.reviewRecommended, isActive: false) == theme.warning)
    }

    @Test func modernSafetyLabelsPreserveExistingText() {
        let theme = AppTheme.modern

        #expect(theme.safetyTitle(.safeToTrash, isActive: false) == SafetyClassification.safeToTrash.displayName)
        #expect(theme.safetyTitle(.unknown, isActive: false) == SafetyClassification.unknown.displayName)
    }

    @Test func classicGlyphsUseTextModeMarkers() {
        let theme = AppTheme.classic

        #expect(theme.classicGlyph(for: "externaldrive") == "[DSK]")
        #expect(theme.classicGlyph(for: "rectangle.grid.2x2") == "[WIN]")
        #expect(theme.classicGlyph(for: "terminal") == "[CMD]")
        #expect(theme.classicGlyph(for: "trash") == "[DEL]")
        #expect(theme.classicGlyph(for: "arrow.clockwise") == "[RUN]")
        #expect(theme.classicGlyph(for: "slider.horizontal.3") == "[CFG]")
        #expect(theme.classicGlyph(for: "power") == "[OFF]")
        #expect(theme.classicGlyph(for: "unmapped.symbol") == "[*]")
    }
}
