import Foundation
import SwiftUI

@Observable
@MainActor
class PremiumManager {
    static let shared = PremiumManager()

    var isPremium: Bool = false
    var currentPlan: PremiumPlan?
    var trialEndDate: Date?

    var isTrialActive: Bool {
        guard let trialEndDate else { return false }
        return Date() < trialEndDate && !isPremium
    }

    var hasFullAccess: Bool {
        isPremium || isTrialActive
    }

    private init() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
        if let trialEnd = UserDefaults.standard.object(forKey: "trialEndDate") as? Date {
            trialEndDate = trialEnd
        }
    }

    func startTrial() {
        trialEndDate = Calendar.current.date(byAdding: .day, value: 7, to: Date())
        UserDefaults.standard.set(trialEndDate, forKey: "trialEndDate")
    }

    func purchase(plan: PremiumPlan) {
        isPremium = true
        currentPlan = plan
        UserDefaults.standard.set(true, forKey: "isPremium")
    }

    func restorePurchase() {
        isPremium = UserDefaults.standard.bool(forKey: "isPremium")
    }
}

nonisolated enum PremiumPlan: String, CaseIterable, Sendable {
    case monthly
    case annual

    var price: String {
        switch self {
        case .monthly: return "₺129"
        case .annual: return "₺1.090"
        }
    }

    var monthlyEquivalent: String {
        switch self {
        case .monthly: return "₺129/ay"
        case .annual: return "₺90/ay"
        }
    }

    var title: String {
        switch self {
        case .monthly: return "Aylık"
        case .annual: return "Yıllık"
        }
    }

    var subtitle: String {
        switch self {
        case .monthly: return "Her ay yenilenir"
        case .annual: return "2 ay bedava · en avantajlı"
        }
    }

    var period: String {
        switch self {
        case .monthly: return "/ay"
        case .annual: return "/yıl"
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
