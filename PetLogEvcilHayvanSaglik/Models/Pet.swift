import Foundation
import SwiftData

@Model
class Pet {
    var id: UUID
    var name: String
    var species: PetSpecies
    var breed: String
    var birthdate: Date
    var sex: PetSex
    var isNeutered: Bool
    var weightTargetKg: Double?
    var photoData: Data?
    var createdAt: Date

    @Relationship(deleteRule: .cascade) var weightLogs: [WeightLog] = []
    @Relationship(deleteRule: .cascade) var vaccineRecords: [VaccineRecord] = []
    @Relationship(deleteRule: .cascade) var medications: [Medication] = []
    @Relationship(deleteRule: .cascade) var vetVisits: [VetVisit] = []
    @Relationship(deleteRule: .cascade) var expenses: [Expense] = []
    @Relationship(deleteRule: .cascade) var foodInventories: [FoodInventory] = []
    @Relationship(deleteRule: .cascade) var photoLogs: [PhotoLog] = []
    @Relationship(deleteRule: .cascade) var feedingLogs: [FeedingLog] = []
    @Relationship(deleteRule: .cascade) var activityLogs: [ActivityLog] = []
    @Relationship(deleteRule: .cascade) var documents: [PetDocument] = []

    init(name: String, species: PetSpecies, breed: String = "", birthdate: Date, sex: PetSex = .unknown, isNeutered: Bool = false, weightTargetKg: Double? = nil) {
        self.id = UUID()
        self.name = name
        self.species = species
        self.breed = breed
        self.birthdate = birthdate
        self.sex = sex
        self.isNeutered = isNeutered
        self.weightTargetKg = weightTargetKg
        self.createdAt = Date()
    }

    var age: String {
        let components = Calendar.current.dateComponents([.year, .month], from: birthdate, to: Date())
        let years = components.year ?? 0
        let months = components.month ?? 0
        if years > 0 {
            return months > 0 ? "\(years) yıl \(months) ay" : "\(years) yıl"
        }
        return "\(months) ay"
    }

    var latestWeight: Double? {
        weightLogs.sorted { $0.date > $1.date }.first?.weightKg
    }

    var nextVaccineDue: VaccineRecord? {
        vaccineRecords
            .filter { $0.dueDate != nil && $0.dueDate! > Date() }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
            .first
    }

    var activeMedications: [Medication] {
        medications.filter { $0.isActive }
    }

    var currentFood: FoodInventory? {
        foodInventories.sorted { $0.startedAt > $1.startedAt }.first
    }
}

nonisolated enum PetSpecies: String, Codable, CaseIterable, Sendable {
    case unspecified = "Belirtilmemiş"
    case dog = "Köpek"
    case cat = "Kedi"
    case bird = "Kuş"
    case rabbit = "Tavşan"
    case fish = "Balık"
    case reptile = "Sürüngen"
    case other = "Diğer"

    var icon: String {
        switch self {
        case .unspecified: return "questionmark.circle.fill"
        case .dog: return "dog.fill"
        case .cat: return "cat.fill"
        case .bird: return "bird.fill"
        case .rabbit: return "rabbit.fill"
        case .fish: return "fish.fill"
        case .reptile: return "lizard.fill"
        case .other: return "pawprint.fill"
        }
    }
}

nonisolated enum PetSex: String, Codable, CaseIterable, Sendable {
    case male = "Erkek"
    case female = "Dişi"
    case unknown = "Belirtilmemiş"
}
