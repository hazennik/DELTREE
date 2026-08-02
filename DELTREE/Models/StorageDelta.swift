import Foundation

struct StorageDelta: Identifiable, Equatable, Codable, Sendable {
    var id = UUID()
    var fromDate: Date?
    var toDate: Date
    var addedBytes: Int64
    var changedBytes: Int64
    var removedBytes: Int64
    var newItems: [StorageItem]
    var changedItems: [StorageItem]
    var removedPaths: [String]

    var growthBytes: Int64 {
        max(0, addedBytes + changedBytes)
    }

    var codexImpactBytes: Int64 {
        (newItems + changedItems)
            .filter { $0.attribution == .codex || $0.attribution == .xcodeViaCodex }
            .reduce(0) { total, item in
                let deltaBytes = Int64(item.metadata["deltaBytes"] ?? "") ?? item.bytes
                return total + max(0, deltaBytes)
            }
    }

    var isEmpty: Bool {
        addedBytes == 0 && changedBytes == 0 && removedBytes == 0 && newItems.isEmpty && changedItems.isEmpty && removedPaths.isEmpty
    }

    static let empty = StorageDelta(
        fromDate: nil,
        toDate: .distantPast,
        addedBytes: 0,
        changedBytes: 0,
        removedBytes: 0,
        newItems: [],
        changedItems: [],
        removedPaths: [])

    static func make(previous: StorageSnapshot?, current: StorageSnapshot) -> StorageDelta {
        guard let previous else {
            return StorageDelta(
                fromDate: nil,
                toDate: current.capturedAt,
                addedBytes: current.codexAttributedBytes,
                changedBytes: 0,
                removedBytes: 0,
                newItems: current.items.filter { $0.attribution == .codex || $0.attribution == .xcodeViaCodex },
                changedItems: [],
                removedPaths: [])
        }

        let previousByPath = Dictionary(uniqueKeysWithValues: previous.items.map { ($0.path, $0) })
        let currentByPath = Dictionary(uniqueKeysWithValues: current.items.map { ($0.path, $0) })
        let newItems = current.items.filter { previousByPath[$0.path] == nil }
        let changedItems = current.items.compactMap { item -> StorageItem? in
            guard let oldItem = previousByPath[item.path] else {
                return nil
            }
            let deltaBytes = item.bytes - oldItem.bytes
            guard deltaBytes > 0 else {
                return nil
            }
            var item = item
            item.metadata["deltaBytes"] = String(deltaBytes)
            return item
        }
        let removedPaths = previous.items
            .map(\.path)
            .filter { currentByPath[$0] == nil }
            .sorted()

        let addedBytes = newItems.reduce(Int64(0)) { $0 + max(Int64(0), $1.bytes) }
        let changedBytes = changedItems.reduce(Int64(0)) { total, item in
            let oldBytes = previousByPath[item.path]?.bytes ?? 0
            return total + max(Int64(0), item.bytes - oldBytes)
        }
        let removedBytes = removedPaths.reduce(Int64(0)) { total, path in
            total + max(Int64(0), previousByPath[path]?.bytes ?? 0)
        }

        return StorageDelta(
            fromDate: previous.capturedAt,
            toDate: current.capturedAt,
            addedBytes: addedBytes,
            changedBytes: changedBytes,
            removedBytes: removedBytes,
            newItems: newItems,
            changedItems: changedItems,
            removedPaths: removedPaths)
    }
}
