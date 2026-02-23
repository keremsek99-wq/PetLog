import SwiftUI

struct AllPetsOverviewView: View {
    let store: PetStore
    let premiumManager: PremiumManager

    @State private var showPaywall = false

    private var pets: [Pet] { store.allPets() }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                headerStats
                spendingOverview
                vaccineOverview
                medicationOverview
                weightOverview
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
        .sheet(isPresented: $showPaywall) {
            PetLogPaywallView(premiumManager: premiumManager)
        }
    }

    // MARK: - Header Stats

    private var headerStats: some View {
        HStack(spacing: 12) {
            overviewStat(
                icon: "pawprint.fill",
                color: .blue,
                value: "\(pets.count)",
                label: "Hayvan"
            )
            overviewStat(
                icon: "turkishlirasign.circle.fill",
                color: .orange,
                value: totalMonthlySpending.formatted(.currency(code: "TRY")),
                label: "Bu Ay"
            )
            overviewStat(
                icon: "syringe.fill",
                color: .red,
                value: "\(totalOverdueVaccines)",
                label: "Gecikmiş"
            )
            overviewStat(
                icon: "pills.fill",
                color: .blue,
                value: "\(totalActiveMeds)",
                label: "İlaç"
            )
        }
    }

    private func overviewStat(icon: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(Circle())
            Text(value)
                .font(.subheadline.weight(.bold))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    // MARK: - Spending Overview

    private var spendingOverview: some View {
        SummaryCard(title: "Toplam Harcama", icon: "chart.pie.fill", iconColor: .orange) {
            VStack(spacing: 10) {
                ForEach(pets, id: \.id) { pet in
                    let monthly = store.monthlySpending(for: pet)
                    HStack(spacing: 8) {
                        petIcon(pet)
                        Text(pet.name)
                            .font(.subheadline)
                        Spacer()
                        Text(monthly.formatted(.currency(code: "TRY")))
                            .font(.subheadline.weight(.semibold))
                    }
                }
                Divider()
                HStack {
                    Text("Toplam")
                        .font(.subheadline.weight(.bold))
                    Spacer()
                    Text(totalMonthlySpending.formatted(.currency(code: "TRY")))
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.orange)
                }
            }
        }
    }

    // MARK: - Vaccine Overview

    private var vaccineOverview: some View {
        SummaryCard(title: "Aşı Durumu", icon: "syringe.fill", iconColor: .purple) {
            if allVaccineItems.isEmpty {
                Text("Aşı kaydı yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(allVaccineItems, id: \.id) { item in
                        HStack(spacing: 8) {
                            petIcon(item.pet)
                            Circle()
                                .fill(item.statusColor)
                                .frame(width: 6, height: 6)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.vaccine.name)
                                    .font(.caption.weight(.medium))
                                Text(item.pet.name)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            if let due = item.vaccine.dueDate {
                                Text(due.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption2)
                                    .foregroundStyle(item.statusColor)
                            }
                            Text(item.statusLabel)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(item.statusColor)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(item.statusColor.opacity(0.12))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Medication Overview

    private var medicationOverview: some View {
        SummaryCard(title: "Aktif İlaçlar", icon: "pills.fill", iconColor: .blue) {
            if allActiveMeds.isEmpty {
                Text("Aktif ilaç yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                VStack(spacing: 8) {
                    ForEach(allActiveMeds, id: \.id) { item in
                        HStack(spacing: 8) {
                            petIcon(item.pet)
                            VStack(alignment: .leading, spacing: 1) {
                                Text(item.med.name)
                                    .font(.caption.weight(.medium))
                                if !item.med.dosage.isEmpty {
                                    Text(item.med.dosage)
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            Spacer()
                            Text(item.med.schedule.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.blue)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.08))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    // MARK: - Weight Overview

    private var weightOverview: some View {
        SummaryCard(title: "Kilo Takibi", icon: "scalemass.fill", iconColor: .green) {
            VStack(spacing: 8) {
                ForEach(pets, id: \.id) { pet in
                    HStack(spacing: 8) {
                        petIcon(pet)
                        Text(pet.name)
                            .font(.subheadline)
                        Spacer()
                        if let weight = pet.latestWeight {
                            Text(String(format: "%.1f kg", weight))
                                .font(.subheadline.weight(.semibold))
                            if let target = pet.weightTargetKg {
                                Text("/ \(String(format: "%.1f", target))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        } else {
                            Text("—")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Helpers

    private func petIcon(_ pet: Pet) -> some View {
        Group {
            if let photoData = pet.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 22, height: 22)
                    .clipShape(Circle())
            } else {
                Image(systemName: pet.species.icon)
                    .font(.caption2)
                    .foregroundStyle(.blue)
                    .frame(width: 22, height: 22)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
    }

    // MARK: - Computed Data

    private var totalMonthlySpending: Double {
        pets.reduce(0) { $0 + store.monthlySpending(for: $1) }
    }

    private var totalOverdueVaccines: Int {
        pets.reduce(0) { $0 + $1.vaccineRecords.filter { $0.isOverdue }.count }
    }

    private var totalActiveMeds: Int {
        pets.reduce(0) { $0 + $1.activeMedications.count }
    }

    private var allVaccineItems: [VaccineItem] {
        pets.flatMap { pet in
            pet.vaccineRecords
                .filter { $0.isOverdue || $0.isDueSoon }
                .map { VaccineItem(pet: pet, vaccine: $0) }
        }
        .sorted { item1, item2 in
            if item1.vaccine.isOverdue && !item2.vaccine.isOverdue { return true }
            if !item1.vaccine.isOverdue && item2.vaccine.isOverdue { return false }
            return (item1.vaccine.dueDate ?? .distantFuture) < (item2.vaccine.dueDate ?? .distantFuture)
        }
    }

    private var allActiveMeds: [MedItem] {
        pets.flatMap { pet in
            pet.activeMedications.map { MedItem(pet: pet, med: $0) }
        }
    }
}

// MARK: - Helper Types

private struct VaccineItem: Identifiable {
    let pet: Pet
    let vaccine: VaccineRecord
    var id: UUID { vaccine.id }

    var statusColor: Color {
        if vaccine.isOverdue { return .red }
        if vaccine.isDueSoon { return .orange }
        return .green
    }

    var statusLabel: String {
        if vaccine.isOverdue { return "Gecikmiş" }
        if vaccine.isDueSoon { return "Yakında" }
        return "Planlandı"
    }
}

private struct MedItem: Identifiable {
    let pet: Pet
    let med: Medication
    var id: UUID { med.id }
}
