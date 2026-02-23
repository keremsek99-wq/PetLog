import Foundation
import SwiftUI
import RevenueCat

@Observable
@MainActor
class PremiumManager {
    static let shared = PremiumManager()

    var isPremium: Bool = false
    var currentOffering: Offering?
    var customerInfo: CustomerInfo?

    var hasFullAccess: Bool {
        isPremium
    }

    private init() {
        Task {
            await checkSubscriptionStatus()
        }
    }

    // MARK: - Configure SDK

    static func configure() {
        Purchases.logLevel = .debug
        Purchases.configure(withAPIKey: Config.revenueCatAPIKey)
    }

    // MARK: - Subscription Status

    func checkSubscriptionStatus() async {
        do {
            let info = try await Purchases.shared.customerInfo()
            self.customerInfo = info
            self.isPremium = info.entitlements[Config.entitlementID]?.isActive == true
        } catch {
            print("PremiumManager: Failed to fetch customer info: \(error)")
        }
    }

    // MARK: - Fetch Offerings

    func fetchOfferings() async {
        do {
            let offerings = try await Purchases.shared.offerings()
            self.currentOffering = offerings.current
        } catch {
            print("PremiumManager: Failed to fetch offerings: \(error)")
        }
    }

    // MARK: - Purchase

    func purchase(package: Package) async -> Bool {
        do {
            let result = try await Purchases.shared.purchase(package: package)
            self.customerInfo = result.customerInfo
            self.isPremium = result.customerInfo.entitlements[Config.entitlementID]?.isActive == true
            return self.isPremium
        } catch let error as ErrorCode {
            if error == .purchaseCancelledError {
                print("PremiumManager: Purchase cancelled")
            } else {
                print("PremiumManager: Purchase failed: \(error)")
            }
            return false
        } catch {
            print("PremiumManager: Purchase failed: \(error)")
            return false
        }
    }

    // MARK: - Restore

    func restorePurchases() async -> Bool {
        do {
            let info = try await Purchases.shared.restorePurchases()
            self.customerInfo = info
            self.isPremium = info.entitlements[Config.entitlementID]?.isActive == true
            return self.isPremium
        } catch {
            print("PremiumManager: Restore failed: \(error)")
            return false
        }
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
