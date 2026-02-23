import Foundation
import SwiftData
import SwiftUI

@Observable
@MainActor
class PetStore {
    private let modelContext: ModelContext

    var selectedPet: Pet?
    var isLoading: Bool = false

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        loadSelectedPet()
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
        if selectedPet == nil {
            selectedPet = pet
        }
    }

    func deletePet(_ pet: Pet) {
        modelContext.delete(pet)
        if selectedPet?.id == pet.id {
            selectedPet = allPets().first
        }
    }

    func addWeightLog(to pet: Pet, weightKg: Double, date: Date, notes: String) {
        let log = WeightLog(date: date, weightKg: weightKg, notes: notes)
        log.pet = pet
        modelContext.insert(log)
    }

    func addVaccine(to pet: Pet, name: String, dateAdministered: Date, dueDate: Date?, vet: String, notes: String) {
        let record = VaccineRecord(name: name, dateAdministered: dateAdministered, dueDate: dueDate, veterinarian: vet, notes: notes)
        record.pet = pet
        modelContext.insert(record)
    }

    func addMedication(to pet: Pet, name: String, dosage: String, schedule: MedicationSchedule, startDate: Date, endDate: Date?, notes: String) {
        let med = Medication(name: name, dosage: dosage, schedule: schedule, startDate: startDate, endDate: endDate, notes: notes)
        med.pet = pet
        modelContext.insert(med)
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
    }

    func addExpense(to pet: Pet, category: ExpenseCategory, amount: Double, date: Date, merchant: String, notes: String, isRecurring: Bool) {
        let expense = Expense(category: category, amount: amount, date: date, merchant: merchant, notes: notes, isRecurring: isRecurring)
        expense.pet = pet
        modelContext.insert(expense)
    }

    func addFood(to pet: Pet, brand: String, bagSizeKg: Double, dailyGrams: Double, startedAt: Date, reorderLink: String) {
        let food = FoodInventory(brand: brand, bagSizeKg: bagSizeKg, dailyGrams: dailyGrams, startedAt: startedAt, reorderLink: reorderLink)
        food.pet = pet
        modelContext.insert(food)
    }

    func deleteWeightLog(_ log: WeightLog) { modelContext.delete(log) }
    func deleteVaccine(_ record: VaccineRecord) { modelContext.delete(record) }
    func deleteMedication(_ med: Medication) { modelContext.delete(med) }
    func deleteVetVisit(_ visit: VetVisit) { modelContext.delete(visit) }
    func deleteExpense(_ expense: Expense) { modelContext.delete(expense) }
    func deleteFood(_ food: FoodInventory) { modelContext.delete(food) }

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
