import Foundation
import SwiftData

@Model
class Medication {
    var id: UUID
    var name: String
    var dosage: String
    var schedule: MedicationSchedule
    var startDate: Date
    var endDate: Date?
    var notes: String
    var pet: Pet?

    init(name: String, dosage: String = "", schedule: MedicationSchedule = .daily, startDate: Date = Date(), endDate: Date? = nil, notes: String = "") {
        self.id = UUID()
        self.name = name
        self.dosage = dosage
        self.schedule = schedule
        self.startDate = startDate
        self.endDate = endDate
        self.notes = notes
    }

    var isActive: Bool {
        guard let endDate else { return true }
        return endDate >= Date()
    }
}

nonisolated enum MedicationSchedule: String, Codable, CaseIterable, Sendable {
    case asNeeded = "Gerektiğinde"
    case daily = "Günlük"
    case twiceDaily = "Günde 2 Kez"
    case weekly = "Haftalık"
    case monthly = "Aylık"
}
