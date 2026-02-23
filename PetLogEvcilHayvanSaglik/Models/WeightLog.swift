import Foundation
import SwiftData

@Model
class WeightLog {
    var id: UUID
    var date: Date
    var weightKg: Double
    var notes: String
    var pet: Pet?

    init(date: Date = Date(), weightKg: Double, notes: String = "") {
        self.id = UUID()
        self.date = date
        self.weightKg = weightKg
        self.notes = notes
    }
}
