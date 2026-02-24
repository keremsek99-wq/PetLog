import SwiftUI
import SwiftData

struct HealthView: View {
    let store: PetStore
    let premiumManager: PremiumManager

    @State private var selectedSection: HealthSection = .weight
    @State private var showAddWeight = false
    @State private var showAddVaccine = false
    @State private var showAddMedication = false
    @State private var showAddVetVisit = false
    @State private var showPaywall = false

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
            .sheet(isPresented: $showPaywall) {
                PetLogPaywallView(premiumManager: premiumManager)
            }
        }
    }

    private func healthContent(_ pet: Pet) -> some View {
        VStack(spacing: 0) {
            Picker("Bölüm", selection: $selectedSection) {
                ForEach(HealthSection.allCases, id: \.self) { section in
                    Text(section.rawValue).tag(section)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.vertical, 8)

            ScrollView {
                VStack(spacing: 16) {
                    switch selectedSection {
                    case .weight:
                        weightSection(pet)
                    case .vaccines:
                        vaccineSection(pet)
                    case .meds:
                        medsSection(pet)
                    case .vetVisits:
                        vetVisitsSection(pet)
                    case .breedHealth:
                        breedHealthSection(pet)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .background(Color(.systemGroupedBackground))
    }

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

    private func vaccineSection(_ pet: Pet) -> some View {
        VStack(spacing: 12) {
            let sorted = pet.vaccineRecords.sorted { $0.dateAdministered > $1.dateAdministered }
            if sorted.isEmpty {
                EmptyStateView(title: "Aşı Kaydı Yok", message: "Evcil hayvanınızın aşı kayıtlarını burada tutun.", icon: "syringe", actionTitle: "Aşı Ekle") {
                    showAddVaccine = true
                }
                .frame(height: 200)
            } else {
                ForEach(sorted, id: \.id) { record in
                    VaccineRow(record: record) {
                        store.deleteVaccine(record)
                    }
                }
            }
        }
    }

    private func medsSection(_ pet: Pet) -> some View {
        VStack(spacing: 12) {
            let active = pet.activeMedications.sorted { $0.name < $1.name }
            let inactive = pet.medications.filter { !$0.isActive }.sorted { $0.name < $1.name }

            if pet.medications.isEmpty {
                EmptyStateView(title: "İlaç Kaydı Yok", message: "Evcil hayvanınızın ilaçlarını ve takvimini takip edin.", icon: "pills", actionTitle: "İlaç Ekle") {
                    showAddMedication = true
                }
                .frame(height: 200)
            } else {
                if !active.isEmpty {
                    SectionHeader(title: "Aktif")
                    ForEach(active, id: \.id) { med in
                        MedicationRow(medication: med) {
                            store.deleteMedication(med)
                        }
                    }
                }
                if !inactive.isEmpty {
                    SectionHeader(title: "Geçmiş")
                    ForEach(inactive, id: \.id) { med in
                        MedicationRow(medication: med) {
                            store.deleteMedication(med)
                        }
                    }
                }
            }
        }
    }

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
                Label("Veteriner Ziyareti Ekle", systemImage: "cross.case.fill")
            }
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .symbolRenderingMode(.hierarchical)
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
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "heart.text.clipboard.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(.orange.opacity(0.6))
                    Text("İrk Bazlı Sağlık Analizi")
                        .font(.title3.weight(.semibold))
                    Text("\(pet.species.rawValue) türüne özel sağlık riskleri, önerilen kontroller ve bakım ipuplarını görün.")
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
        // Fallback: generic species info
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
        // Fallback: generic species risks
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
        // Fallback: generic species checks
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
    case weight = "Kilo"
    case vaccines = "Aşılar"
    case meds = "İlaçlar"
    case vetVisits = "Ziyaretler"
    case breedHealth = "İrk Sağlığı"
}
