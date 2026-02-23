import Foundation
import SwiftData

@Model
class VaccineRecord {
    var id: UUID
    var name: String
    var dateAdministered: Date
    var dueDate: Date?
    var veterinarian: String
    var notes: String
    var pet: Pet?

    init(name: String, dateAdministered: Date = Date(), dueDate: Date? = nil, veterinarian: String = "", notes: String = "") {
        self.id = UUID()
        self.name = name
        self.dateAdministered = dateAdministered
        self.dueDate = dueDate
        self.veterinarian = veterinarian
        self.notes = notes
    }

    var isOverdue: Bool {
        guard let dueDate else { return false }
        return dueDate < Date()
    }

    var isDueSoon: Bool {
        guard let dueDate else { return false }
        let thirtyDays = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
        return dueDate <= thirtyDays && dueDate >= Date()
    }
}
