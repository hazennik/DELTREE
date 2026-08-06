import Foundation
import Testing
@testable import DELTREE

struct DistributionChannelInfoPlistTests {
    @Test func debugAppInfoPlistDeclaresDebugDistributionChannel() throws {
        let value = try #require(Bundle.main.object(forInfoDictionaryKey: DistributionChannel.infoPlistKey) as? String)

        #expect(value == DistributionChannel.debug.rawValue)
        #expect(DistributionChannel.current(bundle: .main) == .debug)
    }
}
