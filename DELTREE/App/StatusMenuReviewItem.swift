import Foundation

struct StatusMenuReviewItem: Hashable, Identifiable, Sendable {
    var id: StorageItem.ID
    var title: String
    var path: String
    var domain: StorageDomain
    var bytes: Int64

    static func make(from item: StorageItem) -> StatusMenuReviewItem {
        StatusMenuReviewItem(
            id: item.id,
            title: item.displayName,
            path: item.path,
            domain: item.domain,
            bytes: item.bytes)
    }
}
