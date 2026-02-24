import SwiftUI

struct MonthlyReportView: View {
    let pet: Pet
    let store: PetStore

    private var currentMonthExpenses: [Expense] {
        let now = Date()
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now
        return pet.expenses.filter { $0.date >= start }.sorted { $0.date > $1.date }
    }

    private var expenseByCategory: [(String, Double)] {
        var map: [String: Double] = [:]
        for e in currentMonthExpenses {
            map[e.category, default: 0] += e.amount
        }
        return map.sorted { $0.value > $1.value }
    }

    private var thisMonthFeedings: Int {
        let now = Date()
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now
        return pet.feedingLogs.filter { $0.date >= start }.count
    }

    private var thisMonthActivities: Int {
        let now = Date()
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now
        return pet.activityLogs.filter { $0.date >= start }.count
    }

    private var thisMonthWalkMinutes: Int {
        let now = Date()
        let start = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: now)) ?? now
        return pet.activityLogs
            .filter { $0.date >= start && $0.activityType == .walk }
            .reduce(0) { $0 + $1.durationMinutes }
    }

    var body: some View {
        List {
            // Overview
            Section("Genel Bakış") {
                HStack(spacing: 20) {
                    overviewStat(value: "\(currentMonthExpenses.count)", label: "Harcama", color: .orange)
                    overviewStat(value: "\(thisMonthFeedings)", label: "Öğün", color: .green)
                    overviewStat(value: "\(thisMonthActivities)", label: "Aktivite", color: .cyan)
                    overviewStat(value: "\(thisMonthWalkMinutes) dk", label: "Yürüyüş", color: .blue)
                }
                .padding(.vertical, 8)
            }

            // Spending
            Section("Harcamalar") {
                let total = store.monthlySpending(for: pet)
                HStack {
                    Text("Toplam")
                        .font(.headline)
                    Spacer()
                    Text(total.formatted(.currency(code: "TRY")))
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.orange)
                }
                .padding(.vertical, 4)

                ForEach(expenseByCategory, id: \.0) { cat, amount in
                    HStack {
                        Text(cat)
                            .font(.subheadline)
                        Spacer()
                        Text(amount.formatted(.currency(code: "TRY")))
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Weight
            Section("Kilo Değişimi") {
                let sorted = pet.weightLogs.sorted { $0.date < $1.date }
                if sorted.count >= 2 {
                    let first = sorted.first!.weightKg
                    let last = sorted.last!.weightKg
                    let diff = last - first
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Güncel: \(String(format: "%.1f", last)) kg")
                                .font(.headline)
                            Text("Değişim: \(diff > 0 ? "+" : "")\(String(format: "%.1f", diff)) kg")
                                .font(.subheadline)
                                .foregroundStyle(abs(diff) < 0.5 ? .green : .orange)
                        }
                        Spacer()
                        Image(systemName: diff > 0.1 ? "arrow.up.right.circle.fill" : (diff < -0.1 ? "arrow.down.right.circle.fill" : "checkmark.circle.fill"))
                            .font(.title2)
                            .foregroundStyle(abs(diff) < 0.5 ? .green : .orange)
                    }
                } else {
                    Text("Yeterli kilo verisi yok")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Health
            Section("Sağlık Özeti") {
                HStack {
                    Label("Aktif İlaç", systemImage: "pills.fill")
                    Spacer()
                    Text("\(pet.activeMedications.count)")
                        .font(.headline)
                }
                HStack {
                    Label("Aşı Kayıtları", systemImage: "syringe.fill")
                    Spacer()
                    Text("\(pet.vaccineRecords.count)")
                        .font(.headline)
                }
                HStack {
                    Label("Vet Ziyareti", systemImage: "cross.case.fill")
                    Spacer()
                    Text("\(pet.vetVisits.count)")
                        .font(.headline)
                }
                if let nextVac = pet.nextVaccineDue {
                    HStack {
                        Label("Sonraki Aşı", systemImage: "calendar")
                        Spacer()
                        Text(nextVac.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "—")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(.purple)
                    }
                }
            }
        }
        .navigationTitle("Aylık Rapor")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func overviewStat(value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(color)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
