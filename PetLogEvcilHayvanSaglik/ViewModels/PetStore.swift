import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
class PetStore {
    private let modelContext: ModelContext

    var selectedPet: Pet?
    var isLoading: Bool = false

    static let freePetLimit = 1

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSelectedPet()
    }

    private func save() {
        do {
            try modelContext.save()
        } catch {
            print("PetStore save error: \(error)")
        }
    }

    private func loadSelectedPet() {
        let descriptor = FetchDescriptor<Pet>(sortBy: [SortDescriptor(\.createdAt)])
        if let pets = try? modelContext.fetch(descriptor), let first = pets.first {
            selectedPet = first
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
            let recent = sortedWeights.suffix(3)
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
            } else if !pet.vetVisits.isEmpty == false {
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
