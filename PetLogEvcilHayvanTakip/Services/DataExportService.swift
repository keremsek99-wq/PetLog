import Foundation

@MainActor
class DataExportService {
    static let shared = DataExportService()
    private init() {}

    func exportJSON(for pet: Pet, store: PetStore) -> String {
        let data = PetExportData(
            exportDate: Date().ISO8601Format(),
            appVersion: "1.0.0",
            pet: PetData(
                name: pet.name,
                species: pet.species.rawValue,
                breed: pet.breed,
                birthdate: pet.birthdate.ISO8601Format(),
                sex: pet.sex.rawValue,
                isNeutered: pet.isNeutered,
                weightTarget: pet.weightTargetKg
            ),
            weightLogs: pet.weightLogs.sorted { $0.date > $1.date }.map {
                WeightLogData(date: $0.date.ISO8601Format(), weightKg: $0.weightKg, notes: $0.notes)
            },
            vaccines: pet.vaccineRecords.sorted { $0.dateAdministered > $1.dateAdministered }.map {
                VaccineData(
                    name: $0.name,
                    dateAdministered: $0.dateAdministered.ISO8601Format(),
                    dueDate: $0.dueDate?.ISO8601Format(),
                    veterinarian: $0.veterinarian,
                    notes: $0.notes
                )
            },
            medications: pet.medications.map {
                MedicationData(
                    name: $0.name,
                    dosage: $0.dosage,
                    schedule: $0.schedule.rawValue,
                    startDate: $0.startDate.ISO8601Format(),
                    endDate: $0.endDate?.ISO8601Format(),
                    notes: $0.notes
                )
            },
            vetVisits: pet.vetVisits.sorted { $0.date > $1.date }.map {
                VetVisitData(
                    date: $0.date.ISO8601Format(),
                    reason: $0.reason,
                    diagnosis: $0.diagnosis,
                    cost: $0.cost,
                    veterinarian: $0.veterinarian,
                    notes: $0.notes
                )
            },
            expenses: pet.expenses.sorted { $0.date > $1.date }.map {
                ExpenseData(
                    category: $0.category.rawValue,
                    amount: $0.amount,
                    date: $0.date.ISO8601Format(),
                    merchant: $0.merchant,
                    notes: $0.notes,
                    isRecurring: $0.isRecurring
                )
            },
            summary: SummaryData(
                monthlySpending: store.monthlySpending(for: pet),
                annualSpending: store.annualSpending(for: pet),
                totalWeightLogs: pet.weightLogs.count,
                totalVaccines: pet.vaccineRecords.count,
                activeMedications: pet.activeMedications.count,
                totalVetVisits: pet.vetVisits.count,
                totalExpenses: pet.expenses.count
            )
        )

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let jsonData = try? encoder.encode(data),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            return "{}"
        }
        return jsonString
    }

    func exportCSV(for pet: Pet) -> String {
        var csv = "Kategori,Tutar,Tarih,Mağaza,Notlar,Düzenli\n"
        for expense in pet.expenses.sorted(by: { $0.date > $1.date }) {
            let row = [
                expense.category.rawValue,
                String(format: "%.2f", expense.amount),
                expense.date.formatted(date: .numeric, time: .omitted),
                expense.merchant,
                expense.notes,
                expense.isRecurring ? "Evet" : "Hayır"
            ].map { "\"\($0)\"" }.joined(separator: ",")
            csv += row + "\n"
        }
        return csv
    }
}

nonisolated struct PetExportData: Codable, Sendable {
    let exportDate: String
    let appVersion: String
    let pet: PetData
    let weightLogs: [WeightLogData]
    let vaccines: [VaccineData]
    let medications: [MedicationData]
    let vetVisits: [VetVisitData]
    let expenses: [ExpenseData]
    let summary: SummaryData
}

nonisolated struct PetData: Codable, Sendable {
    let name: String
    let species: String
    let breed: String
    let birthdate: String
    let sex: String
    let isNeutered: Bool
    let weightTarget: Double?
}

nonisolated struct WeightLogData: Codable, Sendable {
    let date: String
    let weightKg: Double
    let notes: String
}

nonisolated struct VaccineData: Codable, Sendable {
    let name: String
    let dateAdministered: String
    let dueDate: String?
    let veterinarian: String
    let notes: String
}

nonisolated struct MedicationData: Codable, Sendable {
    let name: String
    let dosage: String
    let schedule: String
    let startDate: String
    let endDate: String?
    let notes: String
}

nonisolated struct VetVisitData: Codable, Sendable {
    let date: String
    let reason: String
    let diagnosis: String
    let cost: Double
    let veterinarian: String
    let notes: String
}

nonisolated struct ExpenseData: Codable, Sendable {
    let category: String
    let amount: Double
    let date: String
    let merchant: String
    let notes: String
    let isRecurring: Bool
}

nonisolated struct SummaryData: Codable, Sendable {
    let monthlySpending: Double
    let annualSpending: Double
    let totalWeightLogs: Int
    let totalVaccines: Int
    let activeMedications: Int
    let totalVetVisits: Int
    let totalExpenses: Int
}
