import Foundation

enum SimctlDeviceParser {
    nonisolated static func parse(data: Data) throws -> [SimctlDevice] {
        let payload = try JSONDecoder().decode(Payload.self, from: data)
        return payload.devices.flatMap { runtimeIdentifier, devices in
            devices.map { device in
                SimctlDevice(
                    udid: device.udid,
                    name: device.name,
                    state: device.state,
                    isAvailable: device.resolvedIsAvailable,
                    availabilityError: device.availabilityError,
                    runtimeIdentifier: runtimeIdentifier,
                    dataPath: device.dataPath,
                    logPath: device.logPath,
                    lastBootedAt: FlexibleDateParser.date(from: device.lastBootedAt))
            }
        }
    }
}

nonisolated private struct Payload: Decodable {
    var devices: [String: [DevicePayload]]
}

nonisolated private struct DevicePayload: Decodable {
    var availability: String?
    var availabilityError: String?
    var dataPath: String?
    var logPath: String?
    var name: String
    var state: String
    var udid: String
    var isAvailable: Bool?
    var lastBootedAt: String?

    nonisolated var resolvedIsAvailable: Bool {
        if let isAvailable {
            return isAvailable
        }
        if let availability {
            return availability.localizedCaseInsensitiveContains("unavailable") == false
        }
        return availabilityError == nil
    }
}

private enum FlexibleDateParser {
    nonisolated static func date(from string: String?) -> Date? {
        guard let string, string.isEmpty == false else {
            return nil
        }

        let internetFormatter = ISO8601DateFormatter()
        internetFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = internetFormatter.date(from: string) {
            return date
        }

        internetFormatter.formatOptions = [.withInternetDateTime]
        if let date = internetFormatter.date(from: string) {
            return date
        }

        let xcodeFormatter = DateFormatter()
        xcodeFormatter.locale = Locale(identifier: "en_US_POSIX")
        xcodeFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        return xcodeFormatter.date(from: string)
    }
}
