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
    @State private var showPaywall = false
    @State private var showAllPets = false
    @State private var showAddFeeding = false
    @State private var showAddActivity = false
    @State private var showAddDocument = false
    @State private var showPhotoTimeline = false
    @State private var showAddBehavior = false
    @State private var showAddVaccine = false
    @State private var showDetailCards = false

    private var pet: Pet? { store.selectedPet }
    private var hasMultiplePets: Bool { store.allPets().count > 1 }

    var body: some View {
        NavigationStack {
            Group {
                if let pet {
                    VStack(spacing: 0) {
                        if hasMultiplePets {
                            Picker("Görünüm", selection: $showAllPets) {
                                Text(pet.name).tag(false)
                                Text("Tüm Hayvanlar").tag(true)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                        }

                        if showAllPets {
                            AllPetsOverviewView(store: store, premiumManager: premiumManager)
                        } else {
                            petDashboard(pet)
                        }
                    }
                    .background(Color(.systemGroupedBackground))
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
            .sheet(isPresented: $showPaywall) {
                PetLogPaywallView(premiumManager: premiumManager)
            }
            .sheet(isPresented: $showAddFeeding) {
                AddFeedingSheet(store: store)
            }
            .sheet(isPresented: $showAddActivity) {
                AddActivitySheet(store: store)
            }
            .sheet(isPresented: $showAddDocument) {
                AddDocumentSheet(store: store, premiumManager: premiumManager)
            }
            .sheet(isPresented: $showPhotoTimeline) {
                PhotoTimelineView(store: store, premiumManager: premiumManager)
            }
            .sheet(isPresented: $showAddBehavior) {
                AddBehaviorSheet(store: store)
            }
            .sheet(isPresented: $showAddVaccine) {
                if let pet { AddVaccineSheet(store: store, pet: pet) }
            }
        }
    }

    // MARK: - Main Dashboard

    private func petDashboard(_ pet: Pet) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                petHeader(pet)

                // Contextual greeting
                contextualGreetingBanner(pet)

                // Sick mode alert
                if pet.isSickMode {
                    sickModeAlert(pet)
                }

                PremiumBanner(premiumManager: premiumManager)

                // Weekly summary strip
                weeklySummaryStrip(pet)

                // Species-aware quick actions
                speciesAwareQuickActions(pet)

                // Smart-ordered cards
                smartCards(pet)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .id(store.refreshID)
    }

    // MARK: - Pet Header (Enhanced)

    private func petHeader(_ pet: Pet) -> some View {
        HStack(spacing: 14) {
            if let photoData = pet.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: PetOSColors.speciesGradient(pet.species),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 2.5
                            )
                    )
                    .shadow(color: pet.speciesColor.opacity(0.2), radius: 4, y: 2)
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
                        .frame(width: 60, height: 60)
                    Text(pet.emoji)
                        .font(.largeTitle)
                }
                .shadow(color: pet.speciesColor.opacity(0.2), radius: 4, y: 2)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(pet.name)
                        .font(.title2.weight(.bold))
                    if pet.isSickMode {
                        PulsingDot(color: .red)
                    }
                }
                HStack(spacing: 6) {
                    if pet.species != .unspecified {
                        Text(pet.species.rawValue)
                    }
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

    // MARK: - Contextual Greeting

    private func contextualGreetingBanner(_ pet: Pet) -> some View {
        Text(pet.contextualGreeting)
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 4)
    }

    // MARK: - Sick Mode Alert

    private func sickModeAlert(_ pet: Pet) -> some View {
        ContextualAlertBanner(
            emoji: "🏥",
            message: "\(pet.name) şu an takip altında. Sağlık kayıtlarını güncel tutun.",
            accentColor: .red,
            actionLabel: "Semptom Ekle"
        ) {
            showAddBehavior = true
        }
    }

    // MARK: - Weekly Summary Strip

    private func weeklySummaryStrip(_ pet: Pet) -> some View {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let weeklyExpenses = pet.expenses.filter { $0.date >= weekAgo }
        let weeklyTotal = weeklyExpenses.reduce(0) { $0 + $1.amount }

        let weeklyActivities = pet.activityLogs.filter { $0.date >= weekAgo }
        let weeklyFeedings = pet.feedingLogs.filter { $0.date >= weekAgo }

        var items: [(emoji: String, label: String, value: String)] = []

        items.append(("💰", "bu hafta", weeklyTotal.formatted(.currency(code: "TRY"))))
        if pet.species == .dog {
            let walkMin = weeklyActivities.filter { $0.activityType == .walk }.reduce(0) { $0 + $1.durationMinutes }
            items.append(("🚶", "yürüyüş", "\(walkMin) dk"))
        }
        items.append(("🍽", "öğün", "\(weeklyFeedings.count)"))

        if let vaccine = pet.nextVaccineDue {
            let days = calendar.dateComponents([.day], from: Date(), to: vaccine.dueDate ?? .distantFuture).day ?? 999
            if days <= 30 {
                items.append(("💉", "aşıya", "\(days) gün"))
            }
        }

        return WeeklySummaryBanner(items: items)
    }

    // MARK: - Species-Aware Quick Actions

    private func speciesAwareQuickActions(_ pet: Pet) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                switch pet.species {
                case .dog:
                    QuickActionButton(title: "Beslenme", icon: "fork.knife", color: .orange, emoji: "🍽") { showAddFeeding = true }
                    QuickActionButton(title: "Yürüyüş", icon: "figure.walk", color: .cyan, emoji: "🐕") { showAddActivity = true }
                    QuickActionButton(title: "Harcama", icon: "turkishlirasign.circle.fill", color: .orange, emoji: "💰") { showAddExpense = true }
                    QuickActionButton(title: "Sağlık", icon: "heart.fill", color: .red, emoji: "❤️‍🩹") { showAddBehavior = true }
                case .cat:
                    QuickActionButton(title: "Beslenme", icon: "fork.knife", color: .orange, emoji: "🍽") { showAddFeeding = true }
                    QuickActionButton(title: "Kilo", icon: "scalemass.fill", color: .green, emoji: "⚖️") { showAddWeight = true }
                    QuickActionButton(title: "Harcama", icon: "turkishlirasign.circle.fill", color: .orange, emoji: "💰") { showAddExpense = true }
                    QuickActionButton(title: "Davranış", icon: "brain.head.profile.fill", color: .purple, emoji: "🧠") { showAddBehavior = true }
                case .bird:
                    QuickActionButton(title: "Beslenme", icon: "fork.knife", color: .orange, emoji: "🍽") { showAddFeeding = true }
                    QuickActionButton(title: "Harcama", icon: "turkishlirasign.circle.fill", color: .orange, emoji: "💰") { showAddExpense = true }
                    QuickActionButton(title: "Davranış", icon: "brain.head.profile.fill", color: .purple, emoji: "🧠") { showAddBehavior = true }
                    QuickActionButton(title: "Veteriner", icon: "cross.case.fill", color: .red, emoji: "🏥") { showAddVetVisit = true }
                case .fish:
                    QuickActionButton(title: "Harcama", icon: "turkishlirasign.circle.fill", color: .orange, emoji: "💰") { showAddExpense = true }
                    QuickActionButton(title: "Veteriner", icon: "cross.case.fill", color: .red, emoji: "🏥") { showAddVetVisit = true }
                    QuickActionButton(title: "Davranış", icon: "brain.head.profile.fill", color: .teal, emoji: "🐟") { showAddBehavior = true }
                    QuickActionButton(title: "Belge", icon: "doc.text.fill", color: .blue, emoji: "📄") { showAddDocument = true }
                default:
                    QuickActionButton(title: "Beslenme", icon: "fork.knife", color: .orange, emoji: "🍽") { showAddFeeding = true }
                    QuickActionButton(title: "Kilo", icon: "scalemass.fill", color: .green, emoji: "⚖️") { showAddWeight = true }
                    QuickActionButton(title: "Harcama", icon: "turkishlirasign.circle.fill", color: .orange, emoji: "💰") { showAddExpense = true }
                    QuickActionButton(title: "Sağlık", icon: "heart.fill", color: .red, emoji: "❤️‍🩹") { showAddBehavior = true }
                }
                moreActionsButton
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Smart Card Ordering

    private func smartCards(_ pet: Pet) -> some View {
        VStack(spacing: 12) {
            // 🔴 URGENT: Medication/Vaccine alerts first
            if pet.isSickMode {
                medicationsCard(pet)
            }

            let upcomingVaccine = pet.nextVaccineDue
            if let vaccine = upcomingVaccine, vaccine.isDueSoon {
                vaccineCard(pet, urgent: true)
            }

            // 🟡 ACTIONABLE: Spending + Upcoming events
            HStack(spacing: 12) {
                spendingCard(pet)
                if !pet.isSickMode {
                    medicationsCard(pet)
                }
            }

            if upcomingVaccine == nil || !(upcomingVaccine?.isDueSoon ?? false) {
                vaccineCard(pet, urgent: false)
            }

            // 🟢 INFORMATIONAL: Activity, weight, food (collapsible for healthy pets)
            if pet.isSickMode || showDetailCards {
                todayActivityCard(pet)
                weightCard(pet)
                foodCard(pet)
            } else {
                Button {
                    withAnimation(.spring(duration: 0.4)) {
                        showDetailCards = true
                    }
                } label: {
                    HStack {
                        Image(systemName: "chart.bar.fill")
                            .foregroundStyle(.secondary)
                        Text("Günlük Detaylar")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Image(systemName: "chevron.down")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(14)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 14))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - More Actions Menu

    private var moreActionsButton: some View {
        Menu {
            Button { showAddMedication = true } label: {
                Label("💊 İlaç Ekle", systemImage: "pills.fill")
            }
            Button { showAddVetVisit = true } label: {
                Label("🏥 Veteriner Ziyareti", systemImage: "cross.case.fill")
            }
            Button { showAddVaccine = true } label: {
                Label("💉 Aşı Ekle", systemImage: "syringe.fill")
            }
            Button { showAddBehavior = true } label: {
                Label("🧠 Davranış Kaydet", systemImage: "brain.head.profile.fill")
            }
            Divider()
            Button { showAddWeight = true } label: {
                Label("⚖️ Kilo Kaydet", systemImage: "scalemass.fill")
            }
            Button { showAddActivity = true } label: {
                Label("🏃 Aktivite Ekle", systemImage: "figure.walk")
            }
            Button { showPhotoTimeline = true } label: {
                Label("📸 Fotoğraf", systemImage: "camera.fill")
            }
            Button { showAddDocument = true } label: {
                Label("📄 Belge Ekle", systemImage: "doc.text.fill")
            }
            Button { showAddFood = true } label: {
                Label("🥫 Mama Stok", systemImage: "takeoutbag.and.cup.and.straw.fill")
            }
        } label: {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color.gray.opacity(0.14), Color.gray.opacity(0.06)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    Text("➕")
                        .font(.title2)
                }
                Text("Daha Fazla")
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Summary Cards

    private func weightCard(_ pet: Pet) -> some View {
        GlowCard(title: "Kilo", icon: "scalemass.fill", iconColor: .green, emoji: "⚖️") {
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
        GlowCard(title: "Mama Stoku", icon: "takeoutbag.and.cup.and.straw.fill", iconColor: .orange, emoji: "🥫") {
            if let food = pet.currentFood {
                VStack(alignment: .leading, spacing: 10) {
                    if premiumManager.hasFullAccess {
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
                    } else {
                        Button {
                            showPaywall = true
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(food.brand)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.primary)
                                    Text("Detaylar için Premium'a geçin")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "lock.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        .buttonStyle(.plain)
                    }
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
        GlowCard(title: "Bu Ay", icon: "turkishlirasign.circle.fill", iconColor: PetOSColors.financeOrange, emoji: "💰") {
            let monthly = store.monthlySpending(for: pet)
            Text(monthly.formatted(.currency(code: "TRY")))
                .font(.system(.title3, design: .rounded, weight: .bold))
        }
    }

    private func medicationsCard(_ pet: Pet) -> some View {
        let count = pet.activeMedications.count
        return GlowCard(
            title: "Aktif İlaçlar",
            icon: "pills.fill",
            iconColor: .blue,
            isUrgent: count > 0,
            emoji: "💊"
        ) {
            HStack {
                Text("\(count)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .foregroundStyle(count > 0 ? .primary : .secondary)
                if count > 0 {
                    Spacer()
                    Button {
                        showAddBehavior = true
                    } label: {
                        Text("Durum Kaydet")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
            }
        }
    }

    private func vaccineCard(_ pet: Pet, urgent: Bool) -> some View {
        GlowCard(title: "Sonraki Aşı", icon: "syringe.fill", iconColor: .purple, isUrgent: urgent, emoji: "💉") {
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
                HStack {
                    Text("Yaklaşan aşı yok")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button {
                        showAddVaccine = true
                    } label: {
                        Text("Aşı Ekle")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.purple)
                    }
                }
            }
        }
    }

    private func todayActivityCard(_ pet: Pet) -> some View {
        let today = Calendar.current.startOfDay(for: Date())
        let todayFeedings = pet.feedingLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        let todayActivities = pet.activityLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
        let walkMinutes = todayActivities.filter { $0.activityType == .walk }.reduce(0) { $0 + $1.durationMinutes }

        return GlowCard(title: "Bugünkü Aktivite", icon: "chart.bar.fill", iconColor: .cyan, emoji: "📊") {
            HStack(spacing: 16) {
                VStack(spacing: 2) {
                    Text("\(todayFeedings.count)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text("öğün")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                if pet.species == .dog {
                    VStack(spacing: 2) {
                        Text("\(walkMinutes)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                        Text("dk yürüyüş")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    VStack(spacing: 2) {
                        Text("\(todayActivities.filter { $0.activityType == .potty }.count)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                        Text("tuvalet")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                VStack(spacing: 2) {
                    Text("\(pet.photoLogs.count)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text("fotoğraf")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
        }
    }

    // MARK: - Empty & Navigation States

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
                if store.canAddMorePets(isPremium: premiumManager.hasFullAccess) {
                    showAddPet = true
                } else {
                    showPaywall = true
                }
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
