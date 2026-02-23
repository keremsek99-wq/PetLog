import SwiftUI
import SwiftData

struct DashboardView: View {
    let store: PetStore
    let premiumManager: PremiumManager

    @State private var showAddWeight = false
    @State private var showAddExpense = false
    @State private var showAddMedication = false
    @State private var showAddVetVisit = false
    @State private var showAddFood = false
    @State private var showAddPet = false

    private var pet: Pet? { store.selectedPet }

    var body: some View {
        NavigationStack {
            Group {
                if let pet {
                    petDashboard(pet)
                } else {
                    noPetState
                }
            }
            .navigationTitle("Bugün")
            .toolbar {
                if pet != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        petSwitcherMenu
                    }
                }
            }
            .sheet(isPresented: $showAddWeight) {
                if let pet { AddWeightSheet(store: store, pet: pet) }
            }
            .sheet(isPresented: $showAddExpense) {
                if let pet { AddExpenseSheet(store: store, pet: pet) }
            }
            .sheet(isPresented: $showAddMedication) {
                if let pet { AddMedicationSheet(store: store, pet: pet) }
            }
            .sheet(isPresented: $showAddVetVisit) {
                if let pet { AddVetVisitSheet(store: store, pet: pet) }
            }
            .sheet(isPresented: $showAddFood) {
                if let pet { AddFoodSheet(store: store, pet: pet) }
            }
            .sheet(isPresented: $showAddPet) {
                AddPetSheet(store: store)
            }
        }
    }

    private func petDashboard(_ pet: Pet) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                petHeader(pet)
                PremiumBanner(premiumManager: premiumManager)
                quickActionsRow
                summaryCards(pet)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func petHeader(_ pet: Pet) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 56, height: 56)
                Image(systemName: pet.species.icon)
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(pet.name)
                    .font(.title2.weight(.bold))
                HStack(spacing: 6) {
                    Text(pet.species.rawValue)
                    if !pet.breed.isEmpty {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(pet.breed)
                    }
                    Text("·")
                        .foregroundStyle(.tertiary)
                    Text(pet.age)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.top, 8)
    }

    private var quickActionsRow: some View {
        HStack(spacing: 0) {
            QuickActionButton(title: "Kilo", icon: "scalemass.fill", color: .green) {
                showAddWeight = true
            }
            QuickActionButton(title: "Harcama", icon: "turkishlirasign.circle.fill", color: .orange) {
                showAddExpense = true
            }
            QuickActionButton(title: "İlaç", icon: "pills.fill", color: .blue) {
                showAddMedication = true
            }
            QuickActionButton(title: "Veteriner", icon: "cross.case.fill", color: .red) {
                showAddVetVisit = true
            }
        }
        .padding(.vertical, 4)
    }

    private func summaryCards(_ pet: Pet) -> some View {
        VStack(spacing: 12) {
            weightCard(pet)
            foodCard(pet)

            HStack(spacing: 12) {
                spendingCard(pet)
                medicationsCard(pet)
            }

            vaccineCard(pet)
        }
    }

    private func weightCard(_ pet: Pet) -> some View {
        SummaryCard(title: "Kilo", icon: "scalemass.fill", iconColor: .green) {
            if let weight = pet.latestWeight {
                HStack(alignment: .firstTextBaseline) {
                    Text(String(format: "%.1f", weight))
                        .font(.system(.title, design: .rounded, weight: .bold))
                    Text("kg")
                        .font(.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                    weightTrend(pet)
                }
            } else {
                Button {
                    showAddWeight = true
                } label: {
                    Label("İlk kiloyu kaydet", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.medium))
                }
            }
        }
    }

    private func weightTrend(_ pet: Pet) -> some View {
        let sorted = pet.weightLogs.sorted { $0.date < $1.date }
        let trend: String = {
            guard sorted.count >= 2 else { return "" }
            let diff = sorted.last!.weightKg - sorted[sorted.count - 2].weightKg
            if diff > 0.1 { return "arrow.up.right" }
            if diff < -0.1 { return "arrow.down.right" }
            return "arrow.right"
        }()
        return Group {
            if !trend.isEmpty {
                Image(systemName: trend)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(trend == "arrow.right" ? Color.secondary : (trend == "arrow.up.right" ? Color.orange : Color.green))
                    .padding(6)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Circle())
            }
        }
    }

    private func foodCard(_ pet: Pet) -> some View {
        SummaryCard(title: "Mama Stoku", icon: "takeoutbag.and.cup.and.straw.fill", iconColor: .orange) {
            if let food = pet.currentFood {
                VStack(alignment: .leading, spacing: 10) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("\(food.daysUntilRunout)")
                            .font(.system(.title, design: .rounded, weight: .bold))
                            .foregroundStyle(food.daysUntilRunout <= 3 ? .red : (food.daysUntilRunout <= 7 ? .orange : .primary))
                        Text("gün kaldı")
                            .font(.body)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(food.brand)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(Capsule())
                    }
                    ProgressView(value: food.percentageRemaining)
                        .tint(food.daysUntilRunout <= 3 ? .red : (food.daysUntilRunout <= 7 ? .orange : .green))
                }
            } else {
                Button {
                    showAddFood = true
                } label: {
                    Label("Mama takibi başlat", systemImage: "plus.circle.fill")
                        .font(.subheadline.weight(.medium))
                }
            }
        }
    }

    private func spendingCard(_ pet: Pet) -> some View {
        SummaryCard(title: "Bu Ay", icon: "turkishlirasign.circle.fill", iconColor: .orange) {
            let monthly = store.monthlySpending(for: pet)
            Text(monthly.formatted(.currency(code: "TRY")))
                .font(.system(.title3, design: .rounded, weight: .bold))
        }
    }

    private func medicationsCard(_ pet: Pet) -> some View {
        SummaryCard(title: "Aktif İlaçlar", icon: "pills.fill", iconColor: .blue) {
            let count = pet.activeMedications.count
            Text("\(count)")
                .font(.system(.title3, design: .rounded, weight: .bold))
                .foregroundStyle(count > 0 ? .primary : .secondary)
        }
    }

    private func vaccineCard(_ pet: Pet) -> some View {
        SummaryCard(title: "Sonraki Aşı", icon: "syringe.fill", iconColor: .purple) {
            if let next = pet.nextVaccineDue {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(next.name)
                            .font(.headline)
                        Text("Tarih: \(next.dueDate?.formatted(date: .abbreviated, time: .omitted) ?? "")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if next.isDueSoon {
                        Text("Yakında")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(Capsule())
                    }
                }
            } else {
                Text("Yaklaşan aşı yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var noPetState: some View {
        EmptyStateView(
            title: "PetLog'a Hoş Geldiniz",
            message: "Sağlık ve harcama takibine başlamak için evcil hayvanınızı ekleyin.",
            icon: "pawprint.fill",
            actionTitle: "Hayvan Ekle"
        ) {
            showAddPet = true
        }
    }

    private var petSwitcherMenu: some View {
        Menu {
            let pets = store.allPets()
            ForEach(pets, id: \.id) { p in
                Button {
                    store.selectedPet = p
                } label: {
                    Label(p.name, systemImage: p.species.icon)
                }
            }
            Divider()
            Button {
                showAddPet = true
            } label: {
                Label("Hayvan Ekle", systemImage: "plus")
            }
        } label: {
            Image(systemName: "pawprint.circle.fill")
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
        }
    }
}
