import SwiftUI
import SwiftData

struct HealthView: View {
    let store: PetStore

    @State private var selectedSection: HealthSection = .weight
    @State private var showAddWeight = false
    @State private var showAddVaccine = false
    @State private var showAddMedication = false
    @State private var showAddVetVisit = false

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
}

nonisolated enum HealthSection: String, CaseIterable, Sendable {
    case weight = "Kilo"
    case vaccines = "Aşılar"
    case meds = "İlaçlar"
    case vetVisits = "Ziyaretler"
}
