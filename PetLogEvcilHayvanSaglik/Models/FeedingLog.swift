import Foundation
import SwiftData

@Model
class FeedingLog {
    var id: UUID
    var mealType: MealType
    var portionGrams: Double
    var foodBrand: String
    var notes: String
    var date: Date
    var pet: Pet?

    init(mealType: MealType, portionGrams: Double = 0, foodBrand: String = "", notes: String = "", date: Date = Date()) {
        self.id = UUID()
        self.mealType = mealType
        self.portionGrams = portionGrams
        self.foodBrand = foodBrand
        self.notes = notes
        self.date = date
    }
}

nonisolated enum MealType: String, Codable, CaseIterable, Sendable {
    case breakfast = "Sabah"
    case lunch = "Öğle"
    case dinner = "Akşam"
    case snack = "Atıştırmalık"
    case water = "Su"

    var icon: String {
        switch self {
        case .breakfast: return "sunrise.fill"
        case .lunch: return "sun.max.fill"
        case .dinner: return "moon.fill"
        case .snack: return "carrot.fill"
        case .water: return "drop.fill"
        }
    }

    var color: String {
        switch self {
        case .breakfast: return "orange"
        case .lunch: return "yellow"
        case .dinner: return "purple"
        case .snack: return "green"
        case .water: return "blue"
        }
    }
}
