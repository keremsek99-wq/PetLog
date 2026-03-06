import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
class PetStore {
    private(set) var modelContext: ModelContext
    var refreshID = UUID()

    var selectedPet: Pet? {
        didSet {
            if let id = selectedPet?.id.uuidString {
                UserDefaults.standard.set(id, forKey: "selectedPetID")
            } else {
                UserDefaults.standard.removeObject(forKey: "selectedPetID")
            }
        }
    }
    var isLoading: Bool = false

    static let freePetLimit = 1

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSelectedPet()
    }

    private func save() {
        do {
            try modelContext.save()
            refreshID = UUID()
        } catch {
            print("PetStore save error: \(error)")
        }
    }

    private func loadSelectedPet() {
        let descriptor = FetchDescriptor<Pet>(sortBy: [SortDescriptor(\.createdAt)])
        guard let pets = try? modelContext.fetch(descriptor), !pets.isEmpty else { return }

        // Try to restore saved selection
        if let savedID = UserDefaults.standard.string(forKey: "selectedPetID"),
           let uuid = UUID(uuidString: savedID),
           let saved = pets.first(where: { $0.id == uuid }) {
            selectedPet = saved
        } else {
            selectedPet = pets.first
        }
    }

    func allPets() -> [Pet] {
        let descriptor = FetchDescriptor<Pet>(sortBy: [SortDescriptor(\.name)])
        return (try? modelContext.fetch(descriptor)) ?? []
    }

    func addPet(_ pet: Pet) {
        modelContext.insert(pet)
        save()
        if selectedPet == nil {
            selectedPet = pet
        }
    }

    func canAddMorePets(isPremium: Bool) -> Bool {
        isPremium || allPets().count < Self.freePetLimit
    }

    func deletePet(_ pet: Pet) {
        modelContext.delete(pet)
        save()
        if selectedPet?.id == pet.id {
            selectedPet = allPets().first
        }
    }

    func updatePet(_ pet: Pet, name: String, species: PetSpecies, breed: String, birthdate: Date, sex: PetSex, isNeutered: Bool, weightTargetKg: Double?, photoData: Data?) {
        pet.name = name
        pet.species = species
        pet.breed = breed
        pet.birthdate = birthdate
        pet.sex = sex
        pet.isNeutered = isNeutered
        pet.weightTargetKg = weightTargetKg
        pet.photoData = photoData
        save()
    }

    func addWeightLog(to pet: Pet, weightKg: Double, date: Date, notes: String) {
        let log = WeightLog(date: date, weightKg: weightKg, notes: notes)
        log.pet = pet
        modelContext.insert(log)
        save()
    }

    func addVaccine(to pet: Pet, name: String, dateAdministered: Date, dueDate: Date?, vet: String, notes: String) {
        let record = VaccineRecord(name: name, dateAdministered: dateAdministered, dueDate: dueDate, veterinarian: vet, notes: notes)
        record.pet = pet
        modelContext.insert(record)
        save()
    }

    func addMedication(to pet: Pet, name: String, dosage: String, schedule: MedicationSchedule, startDate: Date, endDate: Date?, notes: String) {
        let med = Medication(name: name, dosage: dosage, schedule: schedule, startDate: startDate, endDate: endDate, notes: notes)
        med.pet = pet
        modelContext.insert(med)
        save()
    }

    func addVetVisit(to pet: Pet, date: Date, reason: String, diagnosis: String, cost: Double, vet: String, notes: String) {
        let visit = VetVisit(date: date, reason: reason, diagnosis: diagnosis, cost: cost, veterinarian: vet, notes: notes)
        visit.pet = pet
        modelContext.insert(visit)
        if cost > 0 {
            let expense = Expense(category: .veterinary, amount: cost, date: date, merchant: vet, notes: "Veteriner ziyareti: \(reason)")
            expense.pet = pet
            modelContext.insert(expense)
        }
        save()
    }

    func addExpense(to pet: Pet, category: ExpenseCategory, amount: Double, date: Date, merchant: String, notes: String, isRecurring: Bool) {
        let expense = Expense(category: category, amount: amount, date: date, merchant: merchant, notes: notes, isRecurring: isRecurring)
        expense.pet = pet
        modelContext.insert(expense)
        save()
    }

    func addFood(to pet: Pet, brand: String, bagSizeKg: Double, dailyGrams: Double, startedAt: Date, reorderLink: String) {
        let food = FoodInventory(brand: brand, bagSizeKg: bagSizeKg, dailyGrams: dailyGrams, startedAt: startedAt, reorderLink: reorderLink)
        food.pet = pet
        modelContext.insert(food)
        save()
    }

    func deleteWeightLog(_ log: WeightLog) { modelContext.delete(log); save() }
    func deleteVaccine(_ record: VaccineRecord) { modelContext.delete(record); save() }
    func deleteMedication(_ med: Medication) { modelContext.delete(med); save() }
    func deleteVetVisit(_ visit: VetVisit) { modelContext.delete(visit); save() }
    func deleteExpense(_ expense: Expense) { modelContext.delete(expense); save() }
    func deleteFood(_ food: FoodInventory) { modelContext.delete(food); save() }
    func deleteActivityLog(_ log: ActivityLog) { modelContext.delete(log); save() }
    func deleteFeedingLog(_ log: FeedingLog) { modelContext.delete(log); save() }
    func deleteBehaviorLog(_ log: BehaviorLog) { modelContext.delete(log); save() }
    func deleteDocument(_ doc: PetDocument) { modelContext.delete(doc); save() }

    func addFeedingLog(to pet: Pet, mealType: MealType, portionGrams: Double, foodBrand: String, notes: String, date: Date) {
        let log = FeedingLog(mealType: mealType, portionGrams: portionGrams, foodBrand: foodBrand, notes: notes, date: date)
        log.pet = pet
        modelContext.insert(log)
        save()
    }

    func addActivityLog(to pet: Pet, activityType: ActivityType, durationMinutes: Int, notes: String, date: Date) {
        let log = ActivityLog(activityType: activityType, durationMinutes: durationMinutes, notes: notes, date: date)
        log.pet = pet
        modelContext.insert(log)
        save()
    }

    func addBehaviorLog(to pet: Pet, behaviorType: BehaviorType, severity: Int, notes: String, date: Date) {
        let log = BehaviorLog(behaviorType: behaviorType, severity: severity, notes: notes, date: date)
        log.pet = pet
        modelContext.insert(log)
        save()
    }

    func addDocument(to pet: Pet, documentType: DocumentType, title: String, imageData: Data?, notes: String, date: Date) {
        let doc = PetDocument(documentType: documentType, title: title, imageData: imageData, notes: notes, date: date)
        doc.pet = pet
        modelContext.insert(doc)
        save()
    }

    func monthlySpending(for pet: Pet) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        return pet.expenses.filter { $0.date >= startOfMonth }.reduce(0) { $0 + $1.amount }
    }

    func annualSpending(for pet: Pet) -> Double {
        let calendar = Calendar.current
        let now = Date()
        let startOfYear = calendar.date(from: calendar.dateComponents([.year], from: now)) ?? now
        return pet.expenses.filter { $0.date >= startOfYear }.reduce(0) { $0 + $1.amount }
    }

    func spendingByCategory(for pet: Pet) -> [(category: ExpenseCategory, amount: Double)] {
        var totals: [ExpenseCategory: Double] = [:]
        let calendar = Calendar.current
        let now = Date()
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        for expense in pet.expenses where expense.date >= startOfMonth {
            totals[expense.category, default: 0] += expense.amount
        }
        return totals.map { (category: $0.key, amount: $0.value) }.sorted { $0.amount > $1.amount }
    }

    func generateInsights(for pet: Pet) -> [Insight] {
        var insights: [Insight] = []

        // Food runout warning
        if let food = pet.currentFood, food.daysUntilRunout <= 7 {
            let severity: InsightSeverity = food.daysUntilRunout <= 3 ? .urgent : .warning
            insights.append(Insight(
                type: .foodRunout,
                severity: severity,
                title: "Mama Azalıyor",
                body: "\(pet.name)'in \(food.brand) maması tahminen \(food.daysUntilRunout) gün içinde bitecek.",
                recommendedAction: food.reorderLink.isEmpty ? "Mama stoklamayı unutmayın!" : "Sipariş vermek için dokunun",
                petName: pet.name
            ))
        }

        // Overdue vaccines
        let overdueVaccines = pet.vaccineRecords.filter { $0.isOverdue }
        for vaccine in overdueVaccines {
            insights.append(Insight(
                type: .vaccineOverdue,
                severity: .urgent,
                title: "Gecikmiş Aşı: \(vaccine.name)",
                body: "\(pet.name)'in \(vaccine.name) aşısı \(vaccine.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "belirsiz") tarihinde yapılması gerekiyordu.",
                recommendedAction: "\(pet.name)'i aşılatmak için veteriner randevusu alın.",
                petName: pet.name
            ))
        }

        // Weight trend detection
        let sortedWeights = pet.weightLogs.sorted { $0.date < $1.date }
        if sortedWeights.count >= 3 {
            let recent = Array(sortedWeights.suffix(3))
            let weights = recent.map { $0.weightKg }
            let isIncreasing = weights[1] > weights[0] && weights[2] > weights[1]
            let isDecreasing = weights[1] < weights[0] && weights[2] < weights[1]
            if isIncreasing || isDecreasing {
                let trend = isIncreasing ? "artıyor" : "azalıyor"
                insights.append(Insight(
                    type: .weightTrend,
                    severity: .warning,
                    title: "Kilo Değişimi Tespit Edildi",
                    body: "\(pet.name)'in kilosu son 3 kayıtta sürekli \(trend).",
                    recommendedAction: "Yakından takip edin ve değişim devam ederse veterinerinize danışın.",
                    petName: pet.name
                ))
            }
        }

        // Weight target tracking
        if let target = pet.weightTargetKg, let current = pet.latestWeight {
            let deviation = abs(current - target) / target
            if deviation > 0.15 {
                let direction = current > target ? "üzerinde" : "altında"
                insights.append(Insight(
                    type: .weightTrend,
                    severity: .warning,
                    title: "Hedef Kilodan Sapma",
                    body: "\(pet.name)'in güncel kilosu (\(String(format: "%.1f", current)) kg) hedef kilonun (\(String(format: "%.1f", target)) kg) %\(Int(deviation * 100)) \(direction).",
                    recommendedAction: "Beslenme planını gözden geçirin ve veterinerinize danışın.",
                    petName: pet.name
                ))
            }
        }

        // High monthly spending
        let monthlySpend = monthlySpending(for: pet)
        if monthlySpend > 5000 {
            insights.append(Insight(
                type: .spendingAnomaly,
                severity: .info,
                title: "Yüksek Aylık Harcama",
                body: "Bu ay \(pet.name) için \(monthlySpend.formatted(.currency(code: "TRY"))) harcadınız.",
                recommendedAction: "Harcamalarınızı gözden geçirip tasarruf fırsatlarını değerlendirin.",
                petName: pet.name
            ))
        }

        // Upcoming vaccines
        let dueSoonVaccines = pet.vaccineRecords.filter { $0.isDueSoon }
        for vaccine in dueSoonVaccines {
            insights.append(Insight(
                type: .vaccineOverdue,
                severity: .info,
                title: "Yaklaşan Aşı: \(vaccine.name)",
                body: "\(pet.name)'in \(vaccine.name) aşısı \(vaccine.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "yakında") yapılmalı.",
                recommendedAction: "Veteriner randevusu alın.",
                petName: pet.name
            ))
        }

        // Vet visit reminder (no visit in 6+ months)
        let lastVisitDate = pet.vetVisits.sorted { $0.date > $1.date }.first?.date
        let sixMonthsAgo = Calendar.current.date(byAdding: .month, value: -6, to: Date())
        if let sixMonthsAgo {
            if let lastVisit = lastVisitDate {
                if lastVisit < sixMonthsAgo {
                    let monthsSince = Calendar.current.dateComponents([.month], from: lastVisit, to: Date()).month ?? 0
                    insights.append(Insight(
                        type: .vetVisitReminder,
                        severity: .info,
                        title: "Veteriner Kontrolü Zamanı",
                        body: "\(pet.name)'in son veteriner ziyaretinden \(monthsSince) ay geçti.",
                        recommendedAction: "Düzenli kontroller için randevu alın.",
                        petName: pet.name
                    ))
                }
            } else if pet.vetVisits.isEmpty {
                insights.append(Insight(
                    type: .vetVisitReminder,
                    severity: .info,
                    title: "İlk Veteriner Kontrolü",
                    body: "\(pet.name) için henüz veteriner ziyareti kaydedilmemiş.",
                    recommendedAction: "Düzenli sağlık kontrolleri için veterinerinize başvurun.",
                    petName: pet.name
                ))
            }
        }

        // Medication ending soon
        let endingSoonMeds = pet.activeMedications.filter { med in
            guard let endDate = med.endDate else { return false }
            let fiveDays = Calendar.current.date(byAdding: .day, value: 5, to: Date()) ?? Date()
            return endDate <= fiveDays && endDate >= Date()
        }
        for med in endingSoonMeds {
            insights.append(Insight(
                type: .missedMedication,
                severity: .warning,
                title: "İlaç Bitiyor: \(med.name)",
                body: "\(pet.name)'in \(med.name) ilacı \(med.endDate?.formatted(date: .abbreviated, time: .omitted) ?? "yakında") sona erecek.",
                recommendedAction: "Veterinerinize danışarak ilaç yenileme veya sonlandırma kararı verin.",
                petName: pet.name
            ))
        }

        // --- NEW ENHANCED RULES ---

        // Activity gap detection (dogs: no walk in 3+ days)
        if pet.species == .dog {
            let walkLogs = pet.activityLogs.filter { $0.activityType == .walk }.sorted { $0.date > $1.date }
            let daysSinceLastWalk = walkLogs.first.map {
                Calendar.current.dateComponents([.day], from: $0.date, to: Date()).day ?? 0
            } ?? 999
            if daysSinceLastWalk >= 3 && !walkLogs.isEmpty {
                insights.append(Insight(
                    type: .general,
                    severity: .warning,
                    title: "Yürüyüş Eksikliği",
                    body: "\(pet.name) son \(daysSinceLastWalk) gündür yürüyüşe çıkmamış. Düzenli egzersiz fiziksel ve zihinsel sağlık için çok önemlidir.",
                    recommendedAction: "Bugün kısa bile olsa bir yürüyüş yapın.",
                    petName: pet.name
                ))
            }
        }

        // Feeding irregularity (no feeding log in 2+ days)
        let lastFeedingDate = pet.feedingLogs.sorted { $0.date > $1.date }.first?.date
        if let lastFeeding = lastFeedingDate {
            let daysSinceLastFeeding = Calendar.current.dateComponents([.day], from: lastFeeding, to: Date()).day ?? 0
            if daysSinceLastFeeding >= 2 {
                insights.append(Insight(
                    type: .general,
                    severity: .info,
                    title: "Beslenme Kaydı Eksik",
                    body: "\(pet.name) için \(daysSinceLastFeeding) gündür beslenme kaydı girilmemiş.",
                    recommendedAction: "Düzenli kayıt tutmak, beslenme düzenini takip etmenizi sağlar.",
                    petName: pet.name
                ))
            }
        }

        // Seasonal health alerts
        let currentMonth = Calendar.current.component(.month, from: Date())
        if (6...8).contains(currentMonth) {
            // Summer heat warning for brachycephalic breeds
            let brachycephalicBreeds = ["French Bulldog", "Pug", "İran Kedisi (Persian)", "Bulldog"]
            if brachycephalicBreeds.contains(pet.breed) {
                insights.append(Insight(
                    type: .general,
                    severity: .warning,
                    title: "Sıcak Hava Uyarısı",
                    body: "\(pet.breed) ırkı sıcağa karşı hassastır. Öğle saatlerinde dışarı çıkmayın ve bol su sağlayın.",
                    recommendedAction: "Serin ortam sağlayın, zorunlu olmadıkça 11:00-16:00 arası dışarı çıkmayın.",
                    petName: pet.name
                ))
            }
        }

        if (3...5).contains(currentMonth) {
            // Spring parasite season
            insights.append(Insight(
                type: .general,
                severity: .info,
                title: "Parazit Sezonu",
                body: "İlkbahar parazit sezonu başladı. \(pet.name)'in iç ve dış parazit korumasını kontrol edin.",
                recommendedAction: "Son parazit ilacı tarihini kontrol edin.",
                petName: pet.name
            ))
        }

        // Breed-specific health risk reminder (every 90 days)
        if let breedInfo = BreedDatabase.breedInfo(species: pet.species, breedName: pet.breed) {
            let dayOfYear = Calendar.current.ordinality(of: .day, in: .year, for: Date()) ?? 0
            if dayOfYear % 90 < 7 && !breedInfo.healthRisks.isEmpty {
                let risk = breedInfo.healthRisks[dayOfYear % breedInfo.healthRisks.count]
                insights.append(Insight(
                    type: .general,
                    severity: .info,
                    title: "\(pet.breed) Irk Uyarısı",
                    body: risk,
                    recommendedAction: "Veteriner kontrolünde bu konuyu da sorun.",
                    petName: pet.name
                ))
            }
        }

        // Spending trend (this month vs last month)
        let calendar = Calendar.current
        let now = Date()
        let startOfThisMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let startOfLastMonth = calendar.date(byAdding: .month, value: -1, to: startOfThisMonth)!
        let lastMonthSpend = pet.expenses.filter { $0.date >= startOfLastMonth && $0.date < startOfThisMonth }.reduce(0) { $0 + $1.amount }
        if lastMonthSpend > 0 && monthlySpend > lastMonthSpend * 1.5 {
            let increase = Int(((monthlySpend - lastMonthSpend) / lastMonthSpend) * 100)
            insights.append(Insight(
                type: .spendingAnomaly,
                severity: .info,
                title: "Harcama Artışı",
                body: "Bu ayki harcamalar geçen aya göre %\(increase) arttı (\(lastMonthSpend.formatted(.currency(code: "TRY"))) → \(monthlySpend.formatted(.currency(code: "TRY")))).",
                recommendedAction: "Artışın nedenini kontrol edin — tek seferlik mi yoksa sürekli mi?",
                petName: pet.name
            ))
        }

        // Kısırlaştırma reminder for unspayed pets > 6 months
        if !pet.isNeutered {
            let ageMonths = calendar.dateComponents([.month], from: pet.birthdate, to: now).month ?? 0
            if ageMonths >= 6 {
                insights.append(Insight(
                    type: .general,
                    severity: .info,
                    title: "Kısırlaştırma Önerisi",
                    body: "\(pet.name) \(ageMonths) aylık ve henüz kısırlaştırılmamış. Kısırlaştırma birçok sağlık riskini azaltır.",
                    recommendedAction: "Veterinerinizle kısırlaştırma zamanlamasını konuşun.",
                    petName: pet.name
                ))
            }
        }

        if insights.isEmpty {
            insights.append(Insight(
                type: .general,
                severity: .info,
                title: "Her Şey Yolunda!",
                body: "\(pet.name) harika görünüyor. Daha iyi öneriler almak için sağlık ve harcama verilerini kaydetmeye devam edin.",
                petName: pet.name
            ))
        }

        return insights.sorted { severityOrder($0.severity) > severityOrder($1.severity) }
    }

    private func severityOrder(_ severity: InsightSeverity) -> Int {
        switch severity {
        case .urgent: return 3
        case .warning: return 2
        case .info: return 1
        }
    }
}
