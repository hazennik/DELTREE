import Foundation

#if canImport(IOKit)
import IOKit.ps
#endif

struct PowerState: Equatable, Sendable {
    var isOnBatteryPower: Bool
    var isLowPowerModeEnabled: Bool
}

protocol PowerStateProviding: Sendable {
    var currentPowerState: PowerState { get }
}

struct BackgroundScanPolicy: Equatable, Sendable {
    var normalMinimumInterval: TimeInterval = 60
    var batteryMinimumInterval: TimeInterval = 10 * 60
    var lowPowerMinimumInterval: TimeInterval = 30 * 60

    static let production = BackgroundScanPolicy()

    func minimumInterval(for powerState: PowerState) -> TimeInterval {
        if powerState.isLowPowerModeEnabled {
            return lowPowerMinimumInterval
        }
        if powerState.isOnBatteryPower {
            return batteryMinimumInterval
        }
        return normalMinimumInterval
    }

    func effectiveInterval(userInterval: TimeInterval, powerState: PowerState) -> TimeInterval {
        max(max(0, userInterval), minimumInterval(for: powerState))
    }
}

struct LivePowerStateProvider: PowerStateProviding {
    var currentPowerState: PowerState {
        PowerState(
            isOnBatteryPower: Self.isOnBatteryPower(),
            isLowPowerModeEnabled: ProcessInfo.processInfo.isLowPowerModeEnabled)
    }

    private static func isOnBatteryPower() -> Bool {
        #if canImport(IOKit)
        guard let powerInfo = IOPSCopyPowerSourcesInfo()?.takeRetainedValue(),
              let sources = IOPSCopyPowerSourcesList(powerInfo)?.takeRetainedValue() as? [CFTypeRef]
        else {
            return false
        }

        for source in sources {
            guard let description = IOPSGetPowerSourceDescription(powerInfo, source)?.takeUnretainedValue() as? [String: Any],
                  let sourceState = description[kIOPSPowerSourceStateKey] as? String
            else {
                continue
            }
            if sourceState == kIOPSBatteryPowerValue {
                return true
            }
            if sourceState == kIOPSACPowerValue {
                return false
            }
        }
        #endif
        return false
    }
}
