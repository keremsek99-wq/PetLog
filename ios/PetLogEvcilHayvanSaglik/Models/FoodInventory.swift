import Foundation
import SwiftData

@Model
class FoodInventory {
    var id: UUID
    var brand: String
    var bagSizeKg: Double
    var dailyGrams: Double
    var startedAt: Date
    var reorderLink: String
    var pet: Pet?

    init(brand: String, bagSizeKg: Double, dailyGrams: Double, startedAt: Date = Date(), reorderLink: String = "") {
        self.id = UUID()
        self.brand = brand
        self.bagSizeKg = bagSizeKg
        self.dailyGrams = dailyGrams
        self.startedAt = startedAt
        self.reorderLink = reorderLink
    }

    var predictedRunoutDate: Date {
        let totalGrams = bagSizeKg * 1000
        let daysRemaining = totalGrams / max(dailyGrams, 1)
        return Calendar.current.date(byAdding: .day, value: Int(daysRemaining), to: startedAt) ?? startedAt
    }

    var daysUntilRunout: Int {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: predictedRunoutDate).day ?? 0
        return max(days, 0)
    }

    var percentageRemaining: Double {
        let totalGrams = bagSizeKg * 1000
        let daysSinceStart = Calendar.current.dateComponents([.day], from: startedAt, to: Date()).day ?? 0
        let consumed = Double(daysSinceStart) * dailyGrams
        return max(0, min(1, (totalGrams - consumed) / totalGrams))
    }
}
