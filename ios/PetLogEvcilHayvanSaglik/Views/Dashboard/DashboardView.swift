import SwiftUI
import SwiftData

// MARK: - Dashboard Sheet Enum

enum DashboardSheet: Identifiable {
    case addWeight, addExpense, addMedication, addVetVisit
    case addFood, addPet, paywall, addFeeding
    case addActivity, addDocument, photoTimeline
    case addBehavior, addVaccine, sickModeOverlay
    
    var id: String { String(describing: self) }
}

struct DashboardView: View {
    let store: PetStore
    let premiumManager: PremiumManager

    @State private var activeSheet: DashboardSheet?
    @State private var showAllPets = false
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
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .addWeight:
                    if let pet { AddWeightSheet(store: store, pet: pet) }
                case .addExpense:
                    if let pet { AddExpenseSheet(store: store, pet: pet) }
                case .addMedication:
                    if let pet { AddMedicationSheet(store: store, pet: pet) }
                case .addVetVisit:
                    if let pet { AddVetVisitSheet(store: store, pet: pet) }
                case .addFood:
                    if let pet { AddFoodSheet(store: store, pet: pet) }
                case .addPet:
                    AddPetSheet(store: store)
                case .paywall:
                    PetLogPaywallView(premiumManager: premiumManager)
                case .addFeeding:
                    AddFeedingSheet(store: store)
                case .addActivity:
                    AddActivitySheet(store: store)
                case .addDocument:
                    AddDocumentSheet(store: store, premiumManager: premiumManager)
                case .photoTimeline:
                    PhotoTimelineView(store: store, premiumManager: premiumManager)
                case .addBehavior:
                    AddBehaviorSheet(store: store)
                case .addVaccine:
                    if let pet { AddVaccineSheet(store: store, pet: pet) }
                case .sickModeOverlay:
                    if let pet { SickModeOverlayView(pet: pet, store: store, premiumManager: premiumManager) }
                }
            }
        }
    }

    // MARK: - Main Dashboard (3-Layer "Sözcü Modu")

    private func petDashboard(_ pet: Pet) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // ━━━ KATMAN 1: DURUM (her zaman görünür) ━━━
                petHeader(pet)
                statusBanner(pet)
                QuickLogPanel(pet: pet, store: store)

                // ━━━ KATMAN 2: GÜNLÜK AKSİYON (vurgulu) ━━━
                actionSuggestionCard(pet)

                if pet.isSickMode {
                    sickModeAlert(pet)
                }

                // Urgent cards only
                urgentCards(pet)

                // ━━━ KATMAN 3: DETAY (collapsible) ━━━
                detailSection(pet)
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .id(store.refreshID)
        .task(id: pet.id) {
            SmartNotificationEngine.scheduleAllSmartNotifications(for: pet)
        }
    }

    // MARK: - Status Banner (StatusEngine)

    private func statusBanner(_ pet: Pet) -> some View {
        let status = StatusEngine.dailyStatus(for: pet)
        let bgColor: Color = switch status.level {
        case .great: .green
        case .attention: .orange
        case .warning: .red
        case .critical: .red
        }

        return HStack(spacing: 10) {
            Text(status.emoji)
                .font(.title2)
            VStack(alignment: .leading, spacing: 2) {
                Text(status.headline)
                    .font(.subheadline.weight(.semibold))
                if let detail = status.detail {
                    Text(detail)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(bgColor.opacity(0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(bgColor.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Action Suggestion Card

    private func actionSuggestionCard(_ pet: Pet) -> some View {
        let suggestion = ActionSuggestionEngine.dailySuggestion(for: pet)

        return Button {
            handleSuggestionAction(suggestion.actionType)
        } label: {
            HStack(spacing: 12) {
                Text(suggestion.emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text(suggestion.message)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    Text(suggestion.actionLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.blue)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(.secondarySystemGroupedBackground))
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: activeSheet)
    }

    private func handleSuggestionAction(_ action: ActionSuggestion.SuggestedAction) {
        switch action {
        case .addVaccine: activeSheet = .addVaccine
        case .addActivity: activeSheet = .addActivity
        case .addFeeding: activeSheet = .addFeeding
        case .orderFood: activeSheet = .addFood
        case .addWeight: activeSheet = .addWeight
        case .addPhoto: activeSheet = .photoTimeline
        case .addVetVisit: activeSheet = .addVetVisit
        case .addBehavior: activeSheet = .addBehavior
        case .none: break
        }
    }

    // MARK: - Urgent Cards Only

    private func urgentCards(_ pet: Pet) -> some View {
        VStack(spacing: 12) {
            if pet.isSickMode {
                medicationsCard(pet)
            }

            let upcomingVaccine = pet.nextVaccineDue
            if let vaccine = upcomingVaccine, vaccine.isDueSoon {
                vaccineCard(pet, urgent: true)
            }

            // Overdue vaccines
            let overdueVaccines = pet.vaccineRecords.filter { $0.isOverdue }
            if !overdueVaccines.isEmpty {
                vaccineCard(pet, urgent: true)
            }
        }
    }

    // MARK: - Detail Section (Collapsible)

    @AppStorage("showDashboardDetailSection") private var showDashboardDetailSection = false

    private func detailSection(_ pet: Pet) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.35)) {
                    showDashboardDetailSection.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chart.bar.fill")
                        .foregroundStyle(.secondary)
                    Text("Detaylar & Genel Bakış")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(showDashboardDetailSection ? 180 : 0))
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            if showDashboardDetailSection {
                VStack(spacing: 12) {
                    // Wellness Score
                    WellnessScoreCard(pet: pet)

                    // Spending summary
                    spendingCard(pet)

                    // Milestones & Emergency
                    recentMilestoneBanner(pet)
                    emergencyQuickAccess(pet)

                    // Breed Tip
                    breedTipCard(pet)

                    // Premium
                    PremiumBanner(premiumManager: premiumManager)
                }
                .padding(.top, 12)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
    }

    // MARK: - Collapsible Info Section

    @AppStorage("showDashboardInfoSection") private var showDashboardInfoSection = false

    @ViewBuilder
    private func collapsibleInfoSection(_ pet: Pet) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation(.spring(duration: 0.35)) {
                    showDashboardInfoSection.toggle()
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .foregroundStyle(.secondary)
                    Text("Haftalık Özet & İpuçları")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(showDashboardInfoSection ? 180 : 0))
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 14))
            }
            .buttonStyle(.plain)

            if showDashboardInfoSection {
                VStack(spacing: 12) {
                    weeklySummaryStrip(pet)
                    breedTipCard(pet)
                }
                .padding(.top, 12)
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .opacity
                ))
            }
        }
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
        Button {
            activeSheet = .sickModeOverlay
        } label: {
            HStack(spacing: 12) {
                Text("🏥")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(pet.name) Takip Altında")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.red)
                    Text("Detaylı takip panelini aç")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.red.opacity(0.08))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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

    // MARK: - Daily Breed Tip Card

    @AppStorage("dailyTipEnabled") private var dailyTipEnabled: Bool = true

    @ViewBuilder
    private func breedTipCard(_ pet: Pet) -> some View {
        if dailyTipEnabled {
            let tip = BreedTipsDatabase.dailyTip(species: pet.species, breed: pet.breed)
            let accentColor: Color = switch tip.category {
            case .health: .red
            case .nutrition: .orange
            case .activity: .green
            case .grooming: .purple
            case .care: .blue
            }

            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 2)
                    .fill(accentColor)
                    .frame(width: 4)

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(tip.emoji)
                            .font(.title3)
                        Text(tip.title)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(tip.category.rawValue)
                            .font(.caption2)
                            .foregroundStyle(accentColor)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(accentColor.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Text(tip.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(3)
                }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    // MARK: - Recent Milestone Banner

    @ViewBuilder
    private func recentMilestoneBanner(_ pet: Pet) -> some View {
        let recentMilestones = pet.milestones.sorted { $0.date > $1.date }
        if let latest = recentMilestones.first {
            let daysAgo = Calendar.current.dateComponents([.day], from: latest.date, to: Date()).day ?? 0
            NavigationLink {
                MilestoneTimelineView(store: store, premiumManager: premiumManager)
            } label: {
                HStack(spacing: 12) {
                    Text(latest.emoji)
                        .font(.title2)
                        .frame(width: 44, height: 44)
                        .background(Color.yellow.opacity(0.15))
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(latest.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(daysAgo == 0 ? "Bugün!" : "\(daysAgo) gün önce")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing) {
                        Text("⭐ \(recentMilestones.count)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.orange)
                        Text("anı")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(12)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Emergency Quick Access

    @ViewBuilder
    private func emergencyQuickAccess(_ pet: Pet) -> some View {
        let hasInfo = !pet.allergies.isEmpty || !pet.emergencyVetPhone.isEmpty || !pet.microchipID.isEmpty
        NavigationLink {
            EmergencyCardView(pet: pet)
        } label: {
            HStack(spacing: 12) {
                Text("🚨")
                    .font(.title3)
                    .frame(width: 38, height: 38)
                    .background(Color.red.opacity(0.12))
                    .clipShape(Circle())

                VStack(alignment: .leading, spacing: 2) {
                    Text("Acil Durum Kartı")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text(hasInfo ? "Bilgiler mevcut" : "Henüz bilgi girilmemiş")
                        .font(.caption)
                        .foregroundStyle(hasInfo ? .green : .secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Species-Aware Quick Actions

    private func speciesAwareQuickActions(_ pet: Pet) -> some View {
        VStack(spacing: 8) {
            HStack(spacing: 0) {
                switch pet.species {
                case .dog:
                    QuickActionButton(title: "Beslenme", icon: "fork.knife", color: .orange, emoji: "🍽") { activeSheet = .addFeeding }
                    QuickActionButton(title: "Yürüyüş", icon: "figure.walk", color: .cyan, emoji: "🐕") { activeSheet = .addActivity }
                    QuickActionButton(title: "Harcama", icon: "turkishlirasign.circle.fill", color: .orange, emoji: "💰") { activeSheet = .addExpense }
                    QuickActionButton(title: "Sağlık", icon: "heart.fill", color: .red, emoji: "❤️‍🩹") { activeSheet = .addBehavior }
                case .cat:
                    QuickActionButton(title: "Beslenme", icon: "fork.knife", color: .orange, emoji: "🍽") { activeSheet = .addFeeding }
                    QuickActionButton(title: "Kilo", icon: "scalemass.fill", color: .green, emoji: "⚖️") { activeSheet = .addWeight }
                    QuickActionButton(title: "Harcama", icon: "turkishlirasign.circle.fill", color: .orange, emoji: "💰") { activeSheet = .addExpense }
                    QuickActionButton(title: "Davranış", icon: "brain.head.profile.fill", color: .purple, emoji: "🧠") { activeSheet = .addBehavior }
                case .bird:
                    QuickActionButton(title: "Beslenme", icon: "fork.knife", color: .orange, emoji: "🍽") { activeSheet = .addFeeding }
                    QuickActionButton(title: "Harcama", icon: "turkishlirasign.circle.fill", color: .orange, emoji: "💰") { activeSheet = .addExpense }
                    QuickActionButton(title: "Davranış", icon: "brain.head.profile.fill", color: .purple, emoji: "🧠") { activeSheet = .addBehavior }
                    QuickActionButton(title: "Veteriner", icon: "cross.case.fill", color: .red, emoji: "🏥") { activeSheet = .addVetVisit }
                case .fish:
                    QuickActionButton(title: "Harcama", icon: "turkishlirasign.circle.fill", color: .orange, emoji: "💰") { activeSheet = .addExpense }
                    QuickActionButton(title: "Veteriner", icon: "cross.case.fill", color: .red, emoji: "🏥") { activeSheet = .addVetVisit }
                    QuickActionButton(title: "Davranış", icon: "brain.head.profile.fill", color: .teal, emoji: "🐟") { activeSheet = .addBehavior }
                    QuickActionButton(title: "Belge", icon: "doc.text.fill", color: .blue, emoji: "📄") { activeSheet = .addDocument }
                default:
                    QuickActionButton(title: "Beslenme", icon: "fork.knife", color: .orange, emoji: "🍽") { activeSheet = .addFeeding }
                    QuickActionButton(title: "Kilo", icon: "scalemass.fill", color: .green, emoji: "⚖️") { activeSheet = .addWeight }
                    QuickActionButton(title: "Harcama", icon: "turkishlirasign.circle.fill", color: .orange, emoji: "💰") { activeSheet = .addExpense }
                    QuickActionButton(title: "Sağlık", icon: "heart.fill", color: .red, emoji: "❤️‍🩹") { activeSheet = .addBehavior }
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
            Button { activeSheet = .addMedication } label: {
                Label("İlaç Ekle", systemImage: "pills.fill")
            }
            Button { activeSheet = .addVetVisit } label: {
                Label("Veteriner Ziyareti", systemImage: "cross.case.fill")
            }
            Button { activeSheet = .addVaccine } label: {
                Label("Aşı Ekle", systemImage: "syringe.fill")
            }
            Button { activeSheet = .addBehavior } label: {
                Label("Davranış Kaydet", systemImage: "brain.head.profile.fill")
            }
            Divider()
            Button { activeSheet = .addWeight } label: {
                Label("Kilo Kaydet", systemImage: "scalemass.fill")
            }
            Button { activeSheet = .addActivity } label: {
                Label("Aktivite Ekle", systemImage: "figure.walk")
            }
            Button { activeSheet = .photoTimeline } label: {
                Label("Fotoğraf", systemImage: "camera.fill")
            }
            Button { activeSheet = .addDocument } label: {
                Label("Belge Ekle", systemImage: "doc.text.fill")
            }
            Button { activeSheet = .addFood } label: {
                Label("Mama Stok", systemImage: "takeoutbag.and.cup.and.straw.fill")
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
                    activeSheet = .addWeight
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
            guard sorted.count >= 2, let last = sorted.last, let prev = sorted.dropLast().last else { return "" }
            let diff = last.weightKg - prev.weightKg
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
                            activeSheet = .paywall
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
                    activeSheet = .addFood
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
                        activeSheet = .addBehavior
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
                        activeSheet = .addVaccine
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
            activeSheet = .addPet
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
                    activeSheet = .addPet
                } else {
                    activeSheet = .paywall
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
