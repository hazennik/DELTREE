import Foundation

struct DomainSummary: Identifiable, Hashable {
    var domain: StorageDomain
    var bytes: Int64
    var itemCount: Int

    var id: StorageDomain { domain }
}
