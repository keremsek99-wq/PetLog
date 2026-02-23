import Foundation
import SwiftData

@Model
class Insight {
    var id: UUID
    var type: InsightType
    var severity: InsightSeverity
    var createdAt: Date
    var title: String
    var body: String
    var recommendedAction: String
    var isRead: Bool
    var petName: String

    init(type: InsightType, severity: InsightSeverity, title: String, body: String, recommendedAction: String = "", petName: String = "") {
        self.id = UUID()
        self.type = type
        self.severity = severity
        self.createdAt = Date()
        self.title = title
        self.body = body
        self.recommendedAction = recommendedAction
        self.isRead = false
        self.petName = petName
    }
}

nonisolated enum InsightType: String, Codable, CaseIterable, Sendable {
    case weightTrend = "Kilo Değişimi"
    case spendingAnomaly = "Harcama Uyarısı"
    case missedMedication = "Kaçırılan İlaç"
    case vaccineOverdue = "Aşı Hatırlatma"
    case foodRunout = "Mama Bitmek Üzere"
    case vetVisitReminder = "Veteriner Hatırlatma"
    case general = "Genel"

    var icon: String {
        switch self {
        case .weightTrend: return "chart.line.uptrend.xyaxis"
        case .spendingAnomaly: return "exclamationmark.triangle.fill"
        case .missedMedication: return "pills.fill"
        case .vaccineOverdue: return "syringe.fill"
        case .foodRunout: return "takeoutbag.and.cup.and.straw.fill"
        case .vetVisitReminder: return "cross.case.fill"
        case .general: return "lightbulb.fill"
        }
    }
}

nonisolated enum InsightSeverity: String, Codable, CaseIterable, Sendable {
    case info = "Bilgi"
    case warning = "Uyarı"
    case urgent = "Acil"
}
