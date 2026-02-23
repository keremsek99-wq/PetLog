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
    case walk = "Yürüyüş"
    case play = "Oyun"
    case potty = "Tuvalet"
    case grooming = "Bakım"
    case bath = "Banyo"
    case nailTrim = "Tırnak Kesimi"
    case training = "Eğitim"
    case sleep = "Uyku"
    case other = "Diğer"

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
        }
    }
}
