import Foundation
import SwiftData

@Model
class VetVisit {
    var id: UUID
    var date: Date
    var reason: String
    var diagnosis: String
    var cost: Double
    var veterinarian: String
    var notes: String
    var pet: Pet?

    init(date: Date = Date(), reason: String, diagnosis: String = "", cost: Double = 0, veterinarian: String = "", notes: String = "") {
        self.id = UUID()
        self.date = date
        self.reason = reason
        self.diagnosis = diagnosis
        self.cost = cost
        self.veterinarian = veterinarian
        self.notes = notes
    }
}
