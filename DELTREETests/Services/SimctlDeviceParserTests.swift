import Foundation
import Testing
@testable import DELTREE

struct SimctlDeviceParserTests {
    @Test func mapsDeviceJSON() throws {
        let json = """
        {
          "devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-26-0": [
              {
                "availabilityError": "runtime profile not found",
                "dataPath": "/Users/developer/Library/Developer/CoreSimulator/Devices/ABC",
                "isAvailable": false,
                "lastBootedAt": "2026-07-01T12:34:56Z",
                "name": "iPhone 16 Pro",
                "state": "Shutdown",
                "udid": "ABC"
              }
            ]
          }
        }
        """

        let devices = try SimctlDeviceParser.parse(data: Data(json.utf8))
        let device = try #require(devices.first)

        #expect(device.udid == "ABC")
        #expect(device.name == "iPhone 16 Pro")
        #expect(device.isAvailable == false)
        #expect(device.runtimeIdentifier == "com.apple.CoreSimulator.SimRuntime.iOS-26-0")
        #expect(device.lastBootedAt != nil)
    }
}
