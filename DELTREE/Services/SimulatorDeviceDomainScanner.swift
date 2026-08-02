import Foundation

struct SimulatorDeviceDomainScanner: DomainScanning {
    var domain: StorageDomain { .coreSimulatorDevices }
    private let roots: [URL]

    init(roots: [URL]) {
        self.roots = roots
    }

    func scan(context: DomainScanContext) async -> DomainScanResult {
        var result = DomainScanResult.empty

        for root in roots {
            if Task.isCancelled {
                break
            }

            let rootPath = root.standardizedFileURL.path
            guard context.configuration.isExcluded(rootPath) == false else {
                continue
            }

            var isDirectory: ObjCBool = false
            guard context.fileManager.fileExists(atPath: rootPath, isDirectory: &isDirectory), isDirectory.boolValue else {
                result.missingPaths.append(rootPath)
                continue
            }

            let children = (try? context.fileManager.contentsOfDirectory(
                at: root,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: [.skipsHiddenFiles])) ?? []

            for child in children where context.configuration.isExcluded(child.path) == false {
                let device = matchingDevice(for: child, devices: context.simctlDevices)
                let size = context.fileSizeScanner.size(of: child)
                result.unreadablePaths.append(contentsOf: size.unreadablePaths)
                guard size.bytes > 0 else {
                    continue
                }

                var metadata: [String: String] = [
                    "root": rootPath,
                    "suggestedAction": StorageAction.moveToTrash.rawValue,
                ]
                if let device {
                    metadata["udid"] = device.udid
                    metadata["deviceName"] = device.name
                    metadata["state"] = device.state
                    metadata["isAvailable"] = String(device.isAvailable)
                    metadata["runtime"] = device.runtimeIdentifier
                    metadata["availabilityError"] = device.availabilityError
                    if device.isAvailable == false {
                        metadata["suggestedAction"] = StorageAction.deleteUnavailableSimulator.rawValue
                    }
                }
                metadata.merge(CodexSessionMatcher.metadata(for: child.path, sessions: context.codexSessions)) { current, _ in current }

                let item = await StorageItemFactory.makeItem(
                    url: child,
                    domain: .coreSimulatorDevices,
                    kind: .simulatorDevice,
                    size: size,
                    metadata: metadata,
                    isActive: device?.isBooted == true,
                    explicitLastUsedAt: device?.lastBootedAt,
                    context: context)
                result.items.append(item)
            }
        }

        return result
    }

    private func matchingDevice(for url: URL, devices: [SimctlDevice]) -> SimctlDevice? {
        let path = url.standardizedFileURL.path
        let name = url.lastPathComponent
        return devices.first { device in
            if device.udid == name {
                return true
            }
            guard let dataPath = device.dataPath else {
                return false
            }
            let standardizedDataPath = URL(fileURLWithPath: dataPath).standardizedFileURL.path
            return standardizedDataPath == path || standardizedDataPath.hasPrefix(path + "/")
        }
    }
}
