import Foundation
import SwiftUI
import StoreKit

@Observable
@MainActor
class PremiumManager {
    static let shared = PremiumManager()

    // MARK: - Product IDs
    static let monthlyProductID = "com.petlog.premium.month"
    static let yearlyProductID = "com.petlog.premium.year"
    static let lifetimeProductID = "com.petlog.premium.lifetme"
    static let allProductIDs: Set<String> = [monthlyProductID, yearlyProductID, lifetimeProductID]

    // MARK: - State
    var isPremium: Bool = false
    var products: [Product] = []
    var purchasedProductIDs: Set<String> = []
    var isLoading: Bool = false

    var hasFullAccess: Bool { isPremium }

    @ObservationIgnored private var transactionListener: Task<Void, Error>?

    // MARK: - Init

    private init() {
        transactionListener = listenForTransactions()
        Task {
            await loadProducts()
            await updatePurchasedProducts()
        }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Configure (called from App init)

    static func configure() {
        // StoreKit 2 doesn't need explicit configuration
        // Just accessing .shared triggers init
        _ = PremiumManager.shared
    }

    // MARK: - Load Products

    func loadProducts() async {
        isLoading = true
        do {
            let storeProducts = try await Product.products(for: PremiumManager.allProductIDs)
            products = storeProducts.sorted { price($0) < price($1) }
        } catch {
            print("PremiumManager: Failed to load products: \(error)")
        }
        isLoading = false
    }

    // MARK: - Purchase

    func purchase(_ product: Product) async -> Bool {
        do {
            let result = try await product.purchase()
            switch result {
            case .success(let verification):
                let transaction = checkVerified(verification)
                if let transaction {
                    await transaction.finish()
                    await updatePurchasedProducts()
                    return true
                }
                return false
            case .userCancelled:
                return false
            case .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            print("PremiumManager: Purchase failed: \(error)")
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async -> Bool {
        try? await AppStore.sync()
        await updatePurchasedProducts()
        return isPremium
    }

    // MARK: - Transaction Listener

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached {
            for await result in Transaction.updates {
                if let transaction = await self.checkVerified(result) {
                    await transaction.finish()
                    await self.updatePurchasedProducts()
                }
            }
        }
    }

    // MARK: - Update Status

    func updatePurchasedProducts() async {
        var purchased: Set<String> = []

        for await result in Transaction.currentEntitlements {
            if let transaction = checkVerified(result) {
                purchased.insert(transaction.productID)
            }
        }

        purchasedProductIDs = purchased
        isPremium = !purchased.isEmpty
    }

    // MARK: - Helpers

    private func checkVerified<T>(_ result: VerificationResult<T>) -> T? {
        switch result {
        case .verified(let safe):
            return safe
        case .unverified(_, _):
            return nil
        }
    }

    private func price(_ product: Product) -> Decimal {
        product.price
    }

    // MARK: - Product Helpers

    var monthlyProduct: Product? {
        products.first { $0.id == PremiumManager.monthlyProductID }
    }

    var yearlyProduct: Product? {
        products.first { $0.id == PremiumManager.yearlyProductID }
    }

    var lifetimeProduct: Product? {
        products.first { $0.id == PremiumManager.lifetimeProductID }
    }
}

// MARK: - Product Helpers

nonisolated enum PremiumPlan: String, CaseIterable, Sendable {
    case monthly
    case yearly
    case lifetime

    var title: String {
        switch self {
        case .monthly: return "Aylık"
        case .yearly: return "Yıllık"
        case .lifetime: return "Ömür Boyu"
        }
    }

    var subtitle: String {
        switch self {
        case .monthly: return "Her ay yenilenir"
        case .yearly: return "2 ay bedava · en avantajlı"
        case .lifetime: return "Tek seferlik ödeme"
        }
    }
}

nonisolated enum PremiumFeature: String, CaseIterable, Sendable {
    case unlimitedInsights = "Sınırsız AI Önerileri"
    case foodPrediction = "Mama Bitiş Tahmini Detayları"
    case annualProjection = "Yıllık Gider Projeksiyonu"
    case breedHealth = "Irk Bazlı Sağlık Risk Analizi"
    case pdfExport = "PDF Rapor Dışa Aktarma"
    case advancedReminders = "Gelişmiş Hatırlatmalar"
    case multiPet = "Sınırsız Hayvan Ekleme"

    var icon: String {
        switch self {
        case .unlimitedInsights: return "brain.head.profile.fill"
        case .foodPrediction: return "chart.line.uptrend.xyaxis"
        case .annualProjection: return "calendar.badge.clock"
        case .breedHealth: return "heart.text.clipboard.fill"
        case .pdfExport: return "doc.richtext.fill"
        case .advancedReminders: return "bell.badge.fill"
        case .multiPet: return "pawprint.fill"
        }
    }
}
