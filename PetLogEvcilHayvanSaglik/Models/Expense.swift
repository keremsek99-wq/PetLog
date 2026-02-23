import Foundation
import SwiftData

@Model
class Expense {
    var id: UUID
    var category: ExpenseCategory
    var amount: Double
    var date: Date
    var merchant: String
    var notes: String
    var isRecurring: Bool
    var pet: Pet?

    init(category: ExpenseCategory, amount: Double, date: Date = Date(), merchant: String = "", notes: String = "", isRecurring: Bool = false) {
        self.id = UUID()
        self.category = category
        self.amount = amount
        self.date = date
        self.merchant = merchant
        self.notes = notes
        self.isRecurring = isRecurring
    }
}

nonisolated enum ExpenseCategory: String, Codable, CaseIterable, Sendable {
    case food = "Mama"
    case veterinary = "Veteriner"
    case medication = "İlaç"
    case grooming = "Bakım"
    case supplies = "Malzeme"
    case insurance = "Sigorta"
    case training = "Eğitim"
    case boarding = "Pansiyon"
    case other = "Diğer"

    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .veterinary: return "cross.case.fill"
        case .medication: return "pills.fill"
        case .grooming: return "scissors"
        case .supplies: return "bag.fill"
        case .insurance: return "shield.checkered"
        case .training: return "figure.walk"
        case .boarding: return "house.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var color: String {
        switch self {
        case .food: return "orange"
        case .veterinary: return "red"
        case .medication: return "blue"
        case .grooming: return "pink"
        case .supplies: return "purple"
        case .insurance: return "green"
        case .training: return "yellow"
        case .boarding: return "teal"
        case .other: return "gray"
        }
    }
}
