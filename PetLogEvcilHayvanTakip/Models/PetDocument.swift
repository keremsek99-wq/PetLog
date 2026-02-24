import Foundation
import SwiftData

@Model
class PetDocument {
    var id: UUID
    var documentType: DocumentType
    var title: String
    var imageData: Data?
    var notes: String
    var date: Date
    var pet: Pet?

    init(documentType: DocumentType, title: String, imageData: Data? = nil, notes: String = "", date: Date = Date()) {
        self.id = UUID()
        self.documentType = documentType
        self.title = title
        self.imageData = imageData
        self.notes = notes
        self.date = date
    }
}

nonisolated enum DocumentType: String, Codable, CaseIterable, Sendable {
    case vaccineCard = "Aşı Kartı"
    case microchip = "Çip Belgesi"
    case insurance = "Sigorta"
    case vetReport = "Veteriner Raporu"
    case labResult = "Laboratuvar Sonucu"
    case passport = "Pet Pasaportu"
    case prescription = "Reçete"
    case other = "Diğer"

    var icon: String {
        switch self {
        case .vaccineCard: return "syringe.fill"
        case .microchip: return "sensor.fill"
        case .insurance: return "shield.checkered"
        case .vetReport: return "doc.text.fill"
        case .labResult: return "flask.fill"
        case .passport: return "airplane"
        case .prescription: return "list.clipboard.fill"
        case .other: return "doc.fill"
        }
    }
}
