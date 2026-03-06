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
    @Relationship(deleteRule: .cascade) var behaviorLogs: [BehaviorLog] = []

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

    var emoji: String {
        switch species {
        case .dog: return "🐶"
        case .cat: return "🐱"
        case .bird: return "🐦"
        case .rabbit: return "🐰"
        case .fish: return "🐟"
        case .reptile: return "🦎"
        case .unspecified, .other: return "🐾"
        }
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

    // MARK: - Species-Aware UX

    var relevantActivityTypes: [ActivityType] {
        switch species {
        case .dog:
            return [.walk, .play, .potty, .grooming, .bath, .training, .sleep, .other]
        case .cat:
            return [.play, .grooming, .bath, .sleep, .other]
        case .bird:
            return [.play, .grooming, .sleep, .other]
        case .rabbit:
            return [.play, .grooming, .bath, .other]
        case .fish:
            return [.other]
        case .reptile:
            return [.grooming, .bath, .other]
        case .unspecified, .other:
            return ActivityType.allCases
        }
    }

    var speciesColor: Color {
        PetOSColors.speciesColor(species)
    }

    // MARK: - Sick Mode Detection

    var isSickMode: Bool {
        let hasActiveMeds = !activeMedications.isEmpty
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let recentVetVisit = vetVisits.contains { $0.date >= twoWeeksAgo }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let highSeverityBehaviors = behaviorLogs.filter { $0.date >= sevenDaysAgo && $0.severity >= 4 }
        return hasActiveMeds || recentVetVisit || !highSeverityBehaviors.isEmpty
    }

    // MARK: - Contextual Greeting

    var contextualGreeting: String {
        let calendar = Calendar.current
        let now = Date()

        // Check birthday
        let birthdayComponents = calendar.dateComponents([.month, .day], from: birthdate)
        let todayComponents = calendar.dateComponents([.month, .day], from: now)
        if birthdayComponents.month == todayComponents.month && birthdayComponents.day == todayComponents.day {
            return "\(emoji) Mutlu Doğum Günü \(name)! 🎂"
        }

        // Check medications ending soon
        let endingSoon = activeMedications.filter { med in
            guard let endDate = med.endDate else { return false }
            let fiveDays = calendar.date(byAdding: .day, value: 5, to: now) ?? now
            return endDate <= fiveDays && endDate >= now
        }
        if let med = endingSoon.first {
            let days = calendar.dateComponents([.day], from: now, to: med.endDate ?? now).day ?? 0
            return "💊 \(name)'nın \(med.name) ilacı \(days) gün sonra bitiyor"
        }

        // Check upcoming vaccine
        if let vaccine = nextVaccineDue, vaccine.isDueSoon {
            return "💉 \(name)'nın \(vaccine.name) aşısı yaklaşıyor"
        }

        // Default greeting based on time of day
        let hour = calendar.component(.hour, from: now)
        if hour < 12 {
            return "\(emoji) Günaydın, \(name) nasıl?"
        } else if hour < 18 {
            return "\(emoji) İyi günler! \(name) ile keyifli vakitler"
        } else {
            return "\(emoji) İyi akşamlar! \(name) bugün nasıldı?"
        }
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
