import SwiftUI
import SwiftData

struct HealthView: View {
    let store: PetStore
    let premiumManager: PremiumManager

    @State private var selectedSection: HealthSection = .daily
    @State private var showAddWeight = false
    @State private var showAddVaccine = false
    @State private var showAddMedication = false
    @State private var showAddVetVisit = false
    @State private var showAddActivity = false
    @State private var showAddFeeding = false
    @State private var showAddBehavior = false
    @State private var showPaywall = false
    @State private var showDailyHint = true

    private var pet: Pet? { store.selectedPet }

    var body: some View {
        NavigationStack {
            Group {
                if let pet {
                    healthContent(pet)
                } else {
                    EmptyStateView(title: "Hayvan Seçilmedi", message: "Sağlık takibi için ana ekrandan bir hayvan ekleyin.", icon: "heart.fill")
                }
            }
            .navigationTitle("Sağlık")
            .toolbar {
                if pet != nil {
                    ToolbarItem(placement: .topBarTrailing) {
                        addMenu
                    }
                }
            }
            .sheet(isPresented: $showAddWeight) {
                if let pet { AddWeightSheet(store: store, pet: pet) }
            }
            .sheet(isPresented: $showAddVaccine) {
                if let pet { AddVaccineSheet(store: store, pet: pet) }
            }
            .sheet(isPresented: $showAddMedication) {
                if let pet { AddMedicationSheet(store: store, pet: pet) }
            }
            .sheet(isPresented: $showAddVetVisit) {
                if let pet { AddVetVisitSheet(store: store, pet: pet) }
            }
            .sheet(isPresented: $showAddActivity) {
                AddActivitySheet(store: store)
            }
            .sheet(isPresented: $showAddFeeding) {
                AddFeedingSheet(store: store)
            }
            .sheet(isPresented: $showAddBehavior) {
                AddBehaviorSheet(store: store)
            }
            .sheet(isPresented: $showPaywall) {
                PetLogPaywallView(premiumManager: premiumManager)
            }
        }
    }

    // MARK: - Health Content

    private func healthContent(_ pet: Pet) -> some View {
        VStack(spacing: 0) {
            // Tappable stat grid (replaces horizontal pills)
            healthStatGrid(pet)
                .padding(.horizontal)
                .padding(.vertical, 8)

            ScrollView {
                VStack(spacing: 16) {
                    // Health summary header
                    healthSummaryHeader(pet)

                    // Proactive tools (always visible)
                    proactiveToolLinks(pet)

                    // Section content
                    switch selectedSection {
                    case .daily:
                        dailySection(pet)
                    case .vaccinesMeds:
                        vaccineAndMedsSection(pet)
                    case .vetVisits:
                        vetVisitsSection(pet)
                    case .weight:
                        weightSection(pet)
                    case .breedHealth:
                        breedHealthSection(pet)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
        .id(store.refreshID)
    }

    // MARK: - Health Summary Header

    private func healthSummaryHeader(_ pet: Pet) -> some View {
        let status = StatusEngine.dailyStatus(for: pet)
        let activemedCount = pet.activeMedications.count
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let weekSymptoms = pet.behaviorLogs.filter { $0.date >= weekAgo }.count

        return VStack(spacing: 8) {
            HStack(spacing: 10) {
                Text(status.emoji)
                    .font(.title2)
                VStack(alignment: .leading, spacing: 2) {
                    Text(status.headline)
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.primary)
                    HStack(spacing: 12) {
                        if activemedCount > 0 {
                            Label("\(activemedCount) ilaç", systemImage: "pills.fill")
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                        if weekSymptoms > 0 {
                            Label("\(weekSymptoms) semptom", systemImage: "exclamationmark.circle.fill")
                                .font(.caption2)
                                .foregroundStyle(.orange)
                        }
                        if let weight = pet.latestWeight {
                            Label(String(format: "%.1f kg", weight), systemImage: "scalemass.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                }
                Spacer()
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 12))
        }
    }

    // MARK: - Proactive Tool Links

    private func proactiveToolLinks(_ pet: Pet) -> some View {
        HStack(spacing: 10) {
            NavigationLink {
                TrendDashboardView(pet: pet, store: store)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.caption)
                        .foregroundStyle(.blue)
                        .frame(width: 28, height: 28)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Circle())
                    Text("Trend Analizi")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            NavigationLink {
                VetPrepView(pet: pet, store: store)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.caption)
                        .foregroundStyle(.green)
                        .frame(width: 28, height: 28)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Circle())
                    Text("Vet Hazırlık")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.primary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 10))
            }
            .buttonStyle(.plain)

            if pet.isSickMode {
                NavigationLink {
                    SymptomTimelineView(pet: pet)
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.caption)
                            .foregroundStyle(.red)
                            .frame(width: 28, height: 28)
                            .background(Color.red.opacity(0.1))
                            .clipShape(Circle())
                        Text("Semptom")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tappable Stat Grid

    private func healthStatGrid(_ pet: Pet) -> some View {
        let grid = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

        return LazyVGrid(columns: grid, spacing: 8) {
            HealthStatCard(
                title: HealthSection.daily.title,
                emoji: "📋",
                value: dailyStatValue(pet),
                isSelected: selectedSection == .daily
            ) {
                withAnimation(.snappy(duration: 0.2)) { selectedSection = .daily }
            }

            HealthStatCard(
                title: HealthSection.vaccinesMeds.title,
                emoji: "💉",
                value: vaccineStatValue(pet),
                isSelected: selectedSection == .vaccinesMeds
            ) {
                withAnimation(.snappy(duration: 0.2)) { selectedSection = .vaccinesMeds }
            }

            HealthStatCard(
                title: HealthSection.vetVisits.title,
                emoji: "🏥",
                value: "\(pet.vetVisits.count) ziyaret",
                isSelected: selectedSection == .vetVisits
            ) {
                withAnimation(.snappy(duration: 0.2)) { selectedSection = .vetVisits }
            }

            HealthStatCard(
                title: HealthSection.weight.title,
                emoji: "⚖️",
                value: pet.latestWeight.map { String(format: "%.1f kg", $0) } ?? "—",
                isSelected: selectedSection == .weight
            ) {
                withAnimation(.snappy(duration: 0.2)) { selectedSection = .weight }
            }

            HealthStatCard(
                title: HealthSection.breedHealth.title,
                emoji: "🧬",
                value: pet.breed.isEmpty ? pet.species.rawValue : pet.breed,
                isSelected: selectedSection == .breedHealth
            ) {
                withAnimation(.snappy(duration: 0.2)) { selectedSection = .breedHealth }
            }
        }
    }

    private func dailyStatValue(_ pet: Pet) -> String {
        let today = Calendar.current.startOfDay(for: Date())
        let count = pet.activityLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }.count
            + pet.feedingLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }.count
        return "\(count) kayıt"
    }

    private func vaccineStatValue(_ pet: Pet) -> String {
        let activeCount = pet.activeMedications.count
        if activeCount > 0 { return "\(activeCount) aktif ilaç" }
        if let next = pet.nextVaccineDue { return next.isDueSoon ? "Yaklaşan!" : "Planlandı" }
        return "Kayıt yok"
    }

    // MARK: - Weight Section

    private func weightSection(_ pet: Pet) -> some View {
        VStack(spacing: 16) {
            WeightChartView(weightLogs: pet.weightLogs.sorted { $0.date < $1.date })

            let sorted = pet.weightLogs.sorted { $0.date > $1.date }
            if sorted.isEmpty {
                EmptyStateView(title: "Kilo Kaydı Yok", message: "Evcil hayvanınızın kilosunu takip etmeye başlayın.", icon: "scalemass", actionTitle: "Kilo Kaydet") {
                    showAddWeight = true
                }
                .frame(height: 200)
            } else {
                ForEach(sorted, id: \.id) { log in
                    WeightLogRow(log: log) {
                        store.deleteWeightLog(log)
                    }
                }
            }
        }
    }

    // MARK: - Vaccines & Meds Section

    private func vaccineAndMedsSection(_ pet: Pet) -> some View {
        VStack(spacing: 16) {
            // Vaccines
            let sortedVaccines = pet.vaccineRecords.sorted { $0.dateAdministered > $1.dateAdministered }
            SectionHeader(title: "💉 Aşılar", action: "Ekle") {
                showAddVaccine = true
            }
            if sortedVaccines.isEmpty {
                EmptyStateView(title: "Aşı Kaydı Yok", message: "Aşı kayıtlarını burada tutun.", icon: "syringe", actionTitle: "Aşı Ekle") {
                    showAddVaccine = true
                }
                .frame(height: 160)
            } else {
                ForEach(sortedVaccines, id: \.id) { record in
                    VaccineRow(record: record) {
                        store.deleteVaccine(record)
                    }
                }
            }

            Divider().padding(.vertical, 4)

            // Medications
            let active = pet.activeMedications.sorted { $0.name < $1.name }
            let inactive = pet.medications.filter { !$0.isActive }.sorted { $0.name < $1.name }
            SectionHeader(title: "💊 İlaçlar", action: "Ekle") {
                showAddMedication = true
            }
            if pet.medications.isEmpty {
                EmptyStateView(title: "İlaç Kaydı Yok", message: "İlaçlarınızı ve takvimini takip edin.", icon: "pills", actionTitle: "İlaç Ekle") {
                    showAddMedication = true
                }
                .frame(height: 160)
            } else {
                if !active.isEmpty {
                    Text("Aktif")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.green)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(active, id: \.id) { med in
                        MedicationRow(medication: med) {
                            store.deleteMedication(med)
                        }
                    }
                }
                if !inactive.isEmpty {
                    Text("Geçmiş")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    ForEach(inactive, id: \.id) { med in
                        MedicationRow(medication: med) {
                            store.deleteMedication(med)
                        }
                    }
                }
            }
        }
    }

    // MARK: - Vet Visits Section

    private func vetVisitsSection(_ pet: Pet) -> some View {
        VStack(spacing: 12) {
            let sorted = pet.vetVisits.sorted { $0.date > $1.date }
            if sorted.isEmpty {
                EmptyStateView(title: "Veteriner Ziyareti Yok", message: "Veteriner ziyaretlerini ve masraflarını kaydedin.", icon: "cross.case", actionTitle: "Ziyaret Ekle") {
                    showAddVetVisit = true
                }
                .frame(height: 200)
            } else {
                ForEach(sorted, id: \.id) { visit in
                    VetVisitRow(visit: visit) {
                        store.deleteVetVisit(visit)
                    }
                }
            }
        }
    }

    // MARK: - Add Menu

    private var addMenu: some View {
        Menu {
            Button { showAddWeight = true } label: {
                Label("Kilo Kaydet", systemImage: "scalemass.fill")
            }
            Button { showAddVaccine = true } label: {
                Label("Aşı Ekle", systemImage: "syringe.fill")
            }
            Button { showAddMedication = true } label: {
                Label("İlaç Ekle", systemImage: "pills.fill")
            }
            Button { showAddVetVisit = true } label: {
                Label("Veteriner Ziyareti", systemImage: "cross.case.fill")
            }
            Divider()
            Button { showAddActivity = true } label: {
                Label("Aktivite Ekle", systemImage: "figure.walk")
            }
            Button { showAddFeeding = true } label: {
                Label("Beslenme Ekle", systemImage: "fork.knife")
            }
            Button { showAddBehavior = true } label: {
                Label("Davranış Kaydet", systemImage: "brain.head.profile.fill")
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
        }
    }

    // MARK: - Daily Section (Activities + Feeding + Behavior)

    private func dailySection(_ pet: Pet) -> some View {
        VStack(spacing: 16) {
            // Feature discovery hint
            FeatureHintBubble(
                message: "Buraya dokunarak ishal, kusma, aşırı su içme gibi belirtiler kaydedebilirsiniz. Tüm davranış ve sağlık verileriniz burada toplanır.",
                icon: "lightbulb.fill",
                isVisible: $showDailyHint
            )

            // Quick add buttons for daily logs
            HStack(spacing: 8) {
                Button { showAddActivity = true } label: {
                    Label("Aktivite", systemImage: "figure.walk")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.cyan.opacity(0.1))
                        .foregroundStyle(.cyan)
                        .clipShape(Capsule())
                }
                Button { showAddFeeding = true } label: {
                    Label("Beslenme", systemImage: "fork.knife")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.orange.opacity(0.1))
                        .foregroundStyle(.orange)
                        .clipShape(Capsule())
                }
                Button { showAddBehavior = true } label: {
                    Label("Davranış", systemImage: "brain.head.profile.fill")
                        .font(.caption.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.purple.opacity(0.1))
                        .foregroundStyle(.purple)
                        .clipShape(Capsule())
                }
                Spacer()
            }

            // Today summary
            let today = Calendar.current.startOfDay(for: Date())
            let todayActivities = pet.activityLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
            let todayFeedings = pet.feedingLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }

            if !todayActivities.isEmpty || !todayFeedings.isEmpty {
                GlowCard(title: "Bugün", icon: "chart.bar.fill", iconColor: .cyan, emoji: "📊") {
                    HStack(spacing: 16) {
                        let walkMin = todayActivities.filter { $0.activityType == .walk }.reduce(0) { $0 + $1.durationMinutes }
                        let pottyCount = todayActivities.filter { $0.activityType == .potty }.count
                        if pet.species == .dog {
                            VStack(spacing: 2) {
                                Text("\(walkMin)")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                Text("dk yürüyüş")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            VStack(spacing: 2) {
                                Text("\(pottyCount)")
                                    .font(.system(.title3, design: .rounded, weight: .bold))
                                Text("tuvalet")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        VStack(spacing: 2) {
                            Text("\(todayFeedings.count)")
                                .font(.system(.title3, design: .rounded, weight: .bold))
                            Text("öğün")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                }
            }

            // Activities
            let sortedActivities = pet.activityLogs.sorted { $0.date > $1.date }
            let sortedFeedings = pet.feedingLogs.sorted { $0.date > $1.date }
            let sortedBehaviors = pet.behaviorLogs.sorted { $0.date > $1.date }

            if sortedActivities.isEmpty && sortedFeedings.isEmpty && sortedBehaviors.isEmpty {
                EmptyStateView(
                    title: "Günlük Kayıt Yok 📝",
                    message: "Yürüyüş, beslenme, tuvalet ve davranış kayıtlarını buradan takip edin.",
                    icon: "figure.walk",
                    actionTitle: "Kayıt Ekle"
                ) {
                    showAddActivity = true
                }
                .frame(height: 200)
            } else {
                if !sortedActivities.isEmpty {
                    SectionHeader(title: "🏃 Aktiviteler")
                    ForEach(sortedActivities.prefix(20), id: \.id) { log in
                        ActivityLogRow(log: log) {
                            store.deleteActivityLog(log)
                        }
                    }
                }

                if !sortedFeedings.isEmpty {
                    SectionHeader(title: "🍽 Beslenme")
                    ForEach(sortedFeedings.prefix(20), id: \.id) { log in
                        FeedingLogRow(log: log) {
                            store.deleteFeedingLog(log)
                        }
                    }
                }

                // Behavior 30-day summary
                let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
                let recentLogs = pet.behaviorLogs.filter { $0.date >= thirtyDaysAgo }
                var counts: [BehaviorType: Int] = [:]
                let _ = recentLogs.forEach { counts[$0.behaviorType, default: 0] += 1 }
                let topSymptoms = counts.sorted { $0.value > $1.value }.prefix(5)

                if !topSymptoms.isEmpty {
                    GlowCard(title: "🧠 Davranış (30 Gün)", icon: "brain.head.profile.fill", iconColor: .orange) {
                        VStack(spacing: 6) {
                            ForEach(Array(topSymptoms), id: \.key) { type, count in
                                HStack(spacing: 8) {
                                    Image(systemName: type.icon)
                                        .font(.caption)
                                        .foregroundStyle(.orange)
                                        .frame(width: 20)
                                    Text(type.rawValue)
                                        .font(.subheadline)
                                    Spacer()
                                    Text("\(count)x")
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(count >= 5 ? .red : .secondary)
                                }
                            }
                        }
                    }
                }

                if !sortedBehaviors.isEmpty {
                    SectionHeader(title: "🧠 Davranış Kayıtları")
                    ForEach(sortedBehaviors.prefix(15), id: \.id) { log in
                        behaviorLogRow(log)
                    }
                }
            }
        }
    }

    private func behaviorLogRow(_ log: BehaviorLog) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color.orange.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: log.behaviorType.icon)
                        .font(.subheadline)
                        .foregroundStyle(.orange)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(log.behaviorType.rawValue)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(log.date.formatted(date: .abbreviated, time: .shortened))
                    if !log.notes.isEmpty {
                        Text("·")
                        Text(log.notes)
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            HStack(spacing: 2) {
                ForEach(1...5, id: \.self) { i in
                    Circle()
                        .fill(i <= log.severity ? severityDotColor(i) : Color(.systemGray5))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
                store.deleteBehaviorLog(log)
            } label: {
                Label("Sil", systemImage: "trash")
            }
        }
        .contextMenu {
            Button("Sil", role: .destructive) {
                store.deleteBehaviorLog(log)
            }
        }
    }

    private func severityDotColor(_ level: Int) -> Color {
        switch level {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .gray
        }
    }

    // MARK: - Breed Health Section (Premium)

    private func breedHealthSection(_ pet: Pet) -> some View {
        VStack(spacing: 16) {
            if premiumManager.hasFullAccess {
                VStack(alignment: .leading, spacing: 12) {
                    breedHealthCard(
                        title: "İrk Bilgisi",
                        icon: "pawprint.fill",
                        color: .blue,
                        items: breedInfoItems(for: pet)
                    )
                    breedHealthCard(
                        title: "Sağlık Riskleri",
                        icon: "exclamationmark.triangle.fill",
                        color: .orange,
                        items: healthRiskItems(for: pet)
                    )
                    breedHealthCard(
                        title: "Önerilen Kontroller",
                        icon: "checkmark.shield.fill",
                        color: .green,
                        items: recommendedCheckItems(for: pet)
                    )

                    // Medical Disclaimer
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.orange)
                        Text(BreedDatabase.medicalDisclaimer)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 10))
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "heart.text.clipboard.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange.opacity(0.6))
                    Text("İrk Bazlı Sağlık Analizi")
                        .font(.title3.weight(.semibold))
                    Text("\(pet.species.rawValue) türüne özel sağlık riskleri, önerilen kontroller ve bakım ipuçlarını görün.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                    Button {
                        showPaywall = true
                    } label: {
                        Label("Premium ile Aç", systemImage: "lock.open.fill")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
            }
        }
    }

    private func breedHealthCard(title: String, icon: String, color: Color, items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
            }
            ForEach(items, id: \.self) { item in
                HStack(alignment: .top, spacing: 8) {
                    Circle()
                        .fill(color.opacity(0.5))
                        .frame(width: 6, height: 6)
                        .padding(.top, 6)
                    Text(item)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
    }

    private func breedInfoItems(for pet: Pet) -> [String] {
        if let info = BreedDatabase.breedInfo(species: pet.species, breedName: pet.breed) {
            return [
                "Yaşam süresi: \(info.lifespan)",
                "Boyut: \(info.size)"
            ] + info.careNotes
        }
        switch pet.species {
        case .dog:
            return [
                "Köpekler ortalama 10-13 yıl yaşar, ırka göre değişir",
                "Düzenli diş bakımı kalp sağlığı için kritiktir",
                "Günlük egzersiz ihtiyacı ırka ve yaşa bağlıdır",
                "💡 Irk seçerek detaylı bilgi alabilirsiniz"
            ]
        case .cat:
            return [
                "Kediler ortalama 15-20 yıl yaşar",
                "Ev kedileri dış kedilerden daha uzun yaşar",
                "Düzenli tırnak bakımı ve diş kontrolleri önemlidir",
                "💡 Irk seçerek detaylı bilgi alabilirsiniz"
            ]
        case .bird:
            return [
                "Kuşlar türe göre 5-80 yıl yaşayabilir",
                "Kafes büyüklüğü ve sosyal etkileşim önemlidir",
                "Hava kalitesi kuş sağlığı için kritiktir"
            ]
        case .rabbit:
            return [
                "Tavşanlar ortalama 8-12 yıl yaşar",
                "Dişleri sürekli büyür, saman ile aşınması gerekir",
                "Sindirim sağlığı için yüksek lifli diyet şarttır"
            ]
        case .fish:
            return [
                "Balıklar türe göre 2-20 yıl yaşayabilir",
                "Su sıcaklığı ve pH dengesi kritik öneme sahiptir",
                "Akvaryum boyutu balık sayısına uygun olmalıdır"
            ]
        case .reptile:
            return [
                "Sürüngenler türe göre 10-50+ yıl yaşayabilir",
                "UVB ışık ve ısı kaynağı zorunludur",
                "Doğru nem oranı deri sağlığı için kritiktir"
            ]
        case .unspecified, .other:
            return [
                "Türüne uygun beslenme ve bakım rehberine başvurun",
                "Düzenli veteriner kontrolleri önemlidir",
                "💡 Tür ve ırk seçerek detaylı bilgi alabilirsiniz"
            ]
        }
    }

    private func healthRiskItems(for pet: Pet) -> [String] {
        if let info = BreedDatabase.breedInfo(species: pet.species, breedName: pet.breed) {
            return info.healthRisks
        }
        switch pet.species {
        case .dog:
            return [
                "Obezite: Düzenli kilo takibi yapın",
                "Eklem sorunları: Büyük ırklarda yaygın",
                "Kulak enfeksiyonları: Haftalık temizlik önerilir"
            ]
        case .cat:
            return [
                "Böbrek hastalığı: Yaşlı kedilerde sık görülür",
                "Diyabet: Aşırı kilolu kedilerde risk artar",
                "İdrar yolu enfeksiyonları: Su tüketimini takip edin"
            ]
        case .bird:
            return [
                "Tüy dökülmesi: Stres ve beslenme eksikliği belirtisi",
                "Solunum yolu hastalıkları: Hava temizliği kritik",
                "Aşırı gagalama: Psikolojik sorun belirtisi olabilir"
            ]
        case .rabbit:
            return [
                "GI Staz: Sindirim durması acil durumdur",
                "Diş problemleri: Yanlış bakımda sık görülür",
                "Sıcak çarpması: 26°C üzerinde risk artar"
            ]
        case .fish:
            return [
                "Beyaz nokta hastalığı (Ich): Stresle tetiklenir",
                "Yüzgeç çürümesi: Kötü su kalitesinin belirtisi",
                "Amonyak zehirlenmesi: Filtre bakımı kritiktir"
            ]
        case .reptile:
            return [
                "Metabolik kemik hastalığı: Kalsiyum eksikliği",
                "Solunum enfeksiyonları: Yanlış sıcaklıkta yaygın",
                "Deri dökülme sorunları: Nem oranı yetersizliği"
            ]
        case .unspecified, .other:
            return [
                "Türe özel hastalıklar için veterinerinize danışın",
                "Beslenme eksiklikleri düzenli kontrol gerektirir",
                "Stres belirtilerini takip edin"
            ]
        }
    }

    private func recommendedCheckItems(for pet: Pet) -> [String] {
        if let info = BreedDatabase.breedInfo(species: pet.species, breedName: pet.breed) {
            return info.recommendedChecks
        }
        switch pet.species {
        case .dog:
            return [
                "Yıllık genel sağlık kontrolü",
                "6 ayda bir diş kontrolü",
                "Aşı takvimi takibi (kuduz, karma)"
            ]
        case .cat:
            return [
                "Yıllık genel kontrol ve kan testi",
                "Yaşlı kedilerde 6 ayda bir böbrek kontrolü",
                "Yıllık aşı takibi"
            ]
        case .bird:
            return [
                "Yıllık genel kontrol",
                "Tüy ve gaga sağlığı değerlendirmesi",
                "Dışkı analizi (parazit kontrolü)"
            ]
        case .rabbit:
            return [
                "6 ayda bir diş kontrolü",
                "Yıllık genel kontrol",
                "Kısırlaştırma değerlendirmesi"
            ]
        case .fish:
            return [
                "Haftalık su parametresi testi",
                "Aylık filtre bakımı",
                "Mevsimsel su sıcaklığı ayarı"
            ]
        case .reptile:
            return [
                "6 ayda bir veteriner kontrolü",
                "Yıllık dışkı parazit analizi",
                "UVB lamba yenileme (6-12 ay)"
            ]
        case .unspecified, .other:
            return [
                "Yıllık veteriner kontrolü",
                "Türe uygun aşı programı",
                "Beslenme değerlendirmesi"
            ]
        }
    }
}

nonisolated enum HealthSection: String, CaseIterable, Sendable {
    case daily = "Günlük"
    case vaccinesMeds = "Aşı & İlaç"
    case vetVisits = "Ziyaretler"
    case weight = "Kilo"
    case breedHealth = "İrk Sağlığı"

    var title: String { rawValue }

    var emoji: String {
        switch self {
        case .weight: return "⚖️"
        case .vaccinesMeds: return "💉"
        case .vetVisits: return "🏥"
        case .daily: return "📋"
        case .breedHealth: return "🧬"
        }
    }
}
