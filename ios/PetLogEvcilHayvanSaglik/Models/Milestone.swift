import Foundation
import SwiftData

@Model
class Milestone {
    var id: UUID
    var title: String
    var emoji: String
    var date: Date
    var notes: String
    var photoData: Data?
    var category: MilestoneCategory
    var pet: Pet?

    init(title: String, emoji: String = "🎉", date: Date = Date(), notes: String = "", category: MilestoneCategory = .custom) {
        self.id = UUID()
        self.title = title
        self.emoji = emoji
        self.date = date
        self.notes = notes
        self.category = category
    }
}

nonisolated enum MilestoneCategory: String, Codable, CaseIterable, Sendable {
    case firstDay = "İlk Gün"
    case health = "Sağlık"
    case training = "Eğitim"
    case social = "Sosyal"
    case growth = "Büyüme"
    case birthday = "Doğum Günü"
    case travel = "Seyahat"
    case custom = "Özel"

    var defaultEmoji: String {
        switch self {
        case .firstDay: return "🏠"
        case .health: return "💊"
        case .training: return "🎓"
        case .social: return "🐾"
        case .growth: return "📏"
        case .birthday: return "🎂"
        case .travel: return "✈️"
        case .custom: return "⭐"
        }
    }
}
