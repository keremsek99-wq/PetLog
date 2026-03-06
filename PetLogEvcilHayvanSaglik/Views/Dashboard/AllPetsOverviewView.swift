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
                petCards
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
                emoji: "🐾",
                color: .blue,
                value: "\(pets.count)",
                label: "Hayvan"
            )
            overviewStat(
                emoji: "💰",
                color: .orange,
                value: totalMonthlySpending.formatted(.currency(code: "TRY")),
                label: "Bu Ay"
            )
            overviewStat(
                emoji: "💉",
                color: .red,
                value: "\(totalOverdueVaccines)",
                label: "Gecikmiş"
            )
            overviewStat(
                emoji: "💊",
                color: .blue,
                value: "\(totalActiveMeds)",
                label: "İlaç"
            )
        }
    }

    private func overviewStat(emoji: String, color: Color, value: String, label: String) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 32, height: 32)
                Text(emoji)
                    .font(.subheadline)
            }
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

    // MARK: - Per-Pet Cards

    private var petCards: some View {
        VStack(spacing: 10) {
            ForEach(pets, id: \.id) { pet in
                petMiniCard(pet)
            }
        }
    }

    private func petMiniCard(_ pet: Pet) -> some View {
        Button {
            store.selectedPet = pet
        } label: {
            HStack(spacing: 12) {
                if let photoData = pet.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 44, height: 44)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: PetOSColors.speciesGradient(pet.species),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                } else {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: PetOSColors.speciesGradient(pet.species),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 44, height: 44)
                        Text(pet.emoji)
                            .font(.title3)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(pet.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        if pet.isSickMode {
                            PulsingDot(color: .red)
                        }
                    }
                    Text("\(pet.species.rawValue) · \(pet.age)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(store.monthlySpending(for: pet).formatted(.currency(code: "TRY")))
                        .font(.caption.weight(.bold))
                    Text("bu ay")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
                    .shadow(color: pet.isSickMode ? Color.red.opacity(0.08) : Color.black.opacity(0.03), radius: 4, y: 2)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(pet.isSickMode ? Color.red.opacity(0.15) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Spending Overview

    private var spendingOverview: some View {
        GlowCard(title: "Toplam Harcama", icon: "chart.pie.fill", iconColor: PetOSColors.financeOrange, emoji: "💰") {
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
        GlowCard(title: "Aşı Durumu", icon: "syringe.fill", iconColor: .purple, isUrgent: totalOverdueVaccines > 0, emoji: "💉") {
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
        GlowCard(title: "Aktif İlaçlar", icon: "pills.fill", iconColor: .blue, isUrgent: totalActiveMeds > 0, emoji: "💊") {
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
        GlowCard(title: "Kilo Takibi", icon: "scalemass.fill", iconColor: .green, emoji: "⚖️") {
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
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: PetOSColors.speciesGradient(pet.species),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 22, height: 22)
                    Text(pet.emoji)
                        .font(.system(size: 11))
                }
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
