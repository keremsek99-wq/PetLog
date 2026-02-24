import SwiftUI

struct DataExportFullView: View {
    let store: PetStore
    let premiumManager: PremiumManager
    @State private var exportType: ExportType = .summary
    @State private var showPaywall = false

    private var pet: Pet? { store.selectedPet }

    var body: some View {
        List {
            Section {
                Text("Evcil hayvanınızın sağlık ve finans verilerini dışa aktarın.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            if let pet {
                Section("\(pet.name) Özeti") {
                    StatRow(label: "Kilo Kayıtları", value: "\(pet.weightLogs.count)", icon: "scalemass.fill", iconColor: .green)
                    StatRow(label: "Aşılar", value: "\(pet.vaccineRecords.count)", icon: "syringe.fill", iconColor: .purple)
                    StatRow(label: "İlaçlar", value: "\(pet.medications.count)", icon: "pills.fill", iconColor: .blue)
                    StatRow(label: "Veteriner Ziyaretleri", value: "\(pet.vetVisits.count)", icon: "cross.case.fill", iconColor: .red)
                    StatRow(label: "Harcamalar", value: "\(pet.expenses.count)", icon: "turkishlirasign.circle.fill", iconColor: .orange)
                }

                Section("Dışa Aktarma Formatı") {
                    Picker("Format", selection: $exportType) {
                        ForEach(ExportType.allCases, id: \.self) { type in
                            Text(type.title).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    switch exportType {
                    case .summary:
                        ShareLink(item: generateSummaryText(pet)) {
                            Label("Özet Paylaş", systemImage: "square.and.arrow.up")
                        }
                    case .json:
                        if premiumManager.hasFullAccess {
                            ShareLink(item: DataExportService.shared.exportJSON(for: pet, store: store)) {
                                Label("JSON Dışa Aktar", systemImage: "doc.badge.arrow.up")
                            }
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    Label("JSON Dışa Aktar", systemImage: "doc.badge.arrow.up")
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    case .csv:
                        if premiumManager.hasFullAccess {
                            ShareLink(item: DataExportService.shared.exportCSV(for: pet)) {
                                Label("CSV Dışa Aktar (Harcamalar)", systemImage: "tablecells")
                            }
                        } else {
                            Button {
                                showPaywall = true
                            } label: {
                                HStack {
                                    Label("CSV Dışa Aktar (Harcamalar)", systemImage: "tablecells")
                                    Spacer()
                                    Image(systemName: "lock.fill")
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Veri Dışa Aktar")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PetLogPaywallView(premiumManager: premiumManager)
        }
    }

    private func generateSummaryText(_ pet: Pet) -> String {
        var text = "PetLog Sağlık & Finans Raporu\n"
        text += "Hayvan: \(pet.name) (\(pet.species.rawValue))\n"
        text += "Yaş: \(pet.age)\n\n"
        if let weight = pet.latestWeight {
            text += "Güncel Kilo: \(String(format: "%.1f", weight)) kg\n"
        }
        text += "Toplam Harcama (Yıl): \(store.annualSpending(for: pet).formatted(.currency(code: "TRY")))\n"
        text += "Aktif İlaçlar: \(pet.activeMedications.count)\n"
        text += "Aşı Kayıtları: \(pet.vaccineRecords.count)\n"
        text += "Veteriner Ziyaretleri: \(pet.vetVisits.count)\n"
        return text
    }
}

nonisolated enum ExportType: String, CaseIterable, Sendable {
    case summary
    case json
    case csv

    var title: String {
        switch self {
        case .summary: return "Özet"
        case .json: return "JSON"
        case .csv: return "CSV"
        }
    }
}
