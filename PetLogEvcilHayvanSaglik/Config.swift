import Foundation

nonisolated enum PetLogConfig {
    // MARK: - StoreKit Product Identifiers
    static let monthlyProductID = "com.petlog.premium.monthly"
    static let yearlyProductID = "com.petlog.premium.yearly"
    static let lifetimeProductID = "com.petlog.premium.lifetime"

    static let allProductIDs: Set<String> = [
        monthlyProductID,
        yearlyProductID,
        lifetimeProductID
    ]
}
