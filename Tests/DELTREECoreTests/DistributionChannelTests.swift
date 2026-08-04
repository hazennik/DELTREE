import Testing
@testable import DELTREECore

struct DistributionChannelTests {
    @Test func parsesInfoDictionaryValues() {
        #expect(DistributionChannel(infoDictionaryValue: "developer-id") == .developerID)
        #expect(DistributionChannel(infoDictionaryValue: "DEVELOPER_ID") == .developerID)
        #expect(DistributionChannel(infoDictionaryValue: "homebrew") == .homebrew)
        #expect(DistributionChannel(infoDictionaryValue: "debug") == .debug)
        #expect(DistributionChannel(infoDictionaryValue: "unknown-value") == .unknown)
        #expect(DistributionChannel(infoDictionaryValue: nil) == .unknown)
    }

    @Test func sparkleUpdatesAreDisabledForHomebrewAndUnknownChannels() {
        #expect(DistributionChannel.developerID.allowsSparkleUpdates)
        #expect(DistributionChannel.debug.allowsSparkleUpdates)
        #expect(DistributionChannel.homebrew.allowsSparkleUpdates == false)
        #expect(DistributionChannel.unknown.allowsSparkleUpdates == false)
    }
}
