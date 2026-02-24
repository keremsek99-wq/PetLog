import Foundation
import SwiftData

@Model
class BehaviorLog {
    var id: UUID
    var behaviorType: BehaviorType
    var severity: Int // 1-5
    var notes: String
    var date: Date
    var pet: Pet?

    init(behaviorType: BehaviorType, severity: Int = 3, notes: String = "", date: Date = Date()) {
        self.id = UUID()
        self.behaviorType = behaviorType
        self.severity = min(5, max(1, severity))
        self.notes = notes
        self.date = date
    }
}

nonisolated enum BehaviorType: String, Codable, CaseIterable, Sendable {
    case barking = "Havlama"
    case biting = "Isırma"
    case scratching = "Tırmalama"
    case itching = "Kaşıntı"
    case hiding = "Saklanma"
    case vomiting = "Kusma"
    case diarrhea = "İshal"
    case lossOfAppetite = "İştahsızlık"
    case excessiveDrinking = "Aşırı Su İçme"
    case limping = "Topallama"
    case sneezing = "Hapşırma"
    case coughing = "Öksürme"
    case aggression = "Saldırganlık"
    case anxiety = "Endişe/Kaygı"
    case other = "Diğer"

    var icon: String {
        switch self {
        case .barking: return "waveform.path"
        case .biting: return "mouth.fill"
        case .scratching: return "hand.raised.fingers.spread.fill"
        case .itching: return "allergens.fill"
        case .hiding: return "eye.slash.fill"
        case .vomiting: return "arrow.up.heart.fill"
        case .diarrhea: return "stomach"
        case .lossOfAppetite: return "fork.knife.circle"
        case .excessiveDrinking: return "drop.triangle.fill"
        case .limping: return "figure.walk.motion"
        case .sneezing: return "nose.fill"
        case .coughing: return "lungs.fill"
        case .aggression: return "exclamationmark.triangle.fill"
        case .anxiety: return "brain.head.profile.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var category: String {
        switch self {
        case .barking, .biting, .scratching, .aggression, .anxiety, .hiding:
            return "Davranış"
        case .itching, .vomiting, .diarrhea, .lossOfAppetite, .excessiveDrinking, .limping, .sneezing, .coughing:
            return "Sağlık Belirtisi"
        case .other:
            return "Diğer"
        }
    }
}
