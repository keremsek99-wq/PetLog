import Foundation
import SwiftData

@Model
class ActivityLog {
    var id: UUID
    var activityType: ActivityType
    var durationMinutes: Int
    var notes: String
    var date: Date
    var pet: Pet?

    init(activityType: ActivityType, durationMinutes: Int = 0, notes: String = "", date: Date = Date()) {
        self.id = UUID()
        self.activityType = activityType
        self.durationMinutes = durationMinutes
        self.notes = notes
        self.date = date
    }
}

nonisolated enum ActivityType: String, Codable, CaseIterable, Sendable {
    // Universal
    case walk = "Yürüyüş"
    case play = "Oyun"
    case potty = "Tuvalet"
    case grooming = "Bakım"
    case bath = "Banyo"
    case nailTrim = "Tırnak Kesimi"
    case training = "Eğitim"
    case sleep = "Uyku"
    case other = "Diğer"
    // Fish-specific
    case waterChange = "Su Değişimi"
    case waterTest = "Su Parametresi"
    case filterMaintenance = "Filtre Bakımı"
    // Bird-specific
    case cageCleaning = "Kafes Temizliği"
    case featherCare = "Tüy Bakımı"
    case flight = "Uçuş"
    // Rabbit-specific
    case hayFeeding = "Saman Takibi"
    case dentalCheck = "Diş Kontrolü"
    // Reptile-specific
    case uvbCheck = "UVB Kontrol"
    case humidityCheck = "Nem Kontrolü"

    var icon: String {
        switch self {
        case .walk: return "figure.walk"
        case .play: return "tennisball.fill"
        case .potty: return "leaf.fill"
        case .grooming: return "scissors"
        case .bath: return "shower.fill"
        case .nailTrim: return "hand.raised.fingers.spread.fill"
        case .training: return "brain.head.profile.fill"
        case .sleep: return "zzz"
        case .other: return "ellipsis.circle.fill"
        case .waterChange: return "drop.triangle.fill"
        case .waterTest: return "testtube.2"
        case .filterMaintenance: return "gearshape.fill"
        case .cageCleaning: return "trash.fill"
        case .featherCare: return "wind"
        case .flight: return "bird.fill"
        case .hayFeeding: return "leaf.arrow.circlepath"
        case .dentalCheck: return "mouth.fill"
        case .uvbCheck: return "sun.max.fill"
        case .humidityCheck: return "humidity.fill"
        }
    }
}
