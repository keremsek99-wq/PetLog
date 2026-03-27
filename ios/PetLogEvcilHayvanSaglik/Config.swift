import Foundation

/// Single source of truth for StoreKit Product Identifiers.
/// These IDs MUST match App Store Connect exactly.
nonisolated enum PetLogConfig {
    // MARK: - StoreKit Product Identifiers
    static let monthlyProductID = "com.petlog.premium.month"
    static let yearlyProductID = "com.petlog.premium.year"
    static let lifetimeProductID = "com.petlog.premium.lifetme"  // NOTE: typo matches ASC, do not change

    static let allProductIDs: Set<String> = [
        monthlyProductID,
        yearlyProductID,
        lifetimeProductID
    ]

    // MARK: - URLs
    static let termsURL = "https://keremsek99-wq.github.io/PetLog/#terms"
    static let privacyURL = "https://keremsek99-wq.github.io/PetLog/#privacy"
    static let supportEmail = "keremsek@duck.com"
}
