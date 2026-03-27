import SwiftUI

/// Generates a shareable HTML health summary for veterinarians
struct VetShareView: View {
    let pet: Pet
    let store: PetStore

    @State private var includeWeight = true
    @State private var includeVaccines = true
    @State private var includeMedications = true
    @State private var includeVetVisits = true
    @State private var includeBehavior = true
    @State private var dateRange: DateRange = .threeMonths

    enum DateRange: String, CaseIterable {
        case oneMonth = "Son 1 Ay"
        case threeMonths = "Son 3 Ay"
        case sixMonths = "Son 6 Ay"
        case oneYear = "Son 1 Yıl"
        case all = "Tüm Zamanlar"

        var date: Date {
            let calendar = Calendar.current
            let now = Date()
            switch self {
            case .oneMonth: return calendar.date(byAdding: .month, value: -1, to: now) ?? now
            case .threeMonths: return calendar.date(byAdding: .month, value: -3, to: now) ?? now
            case .sixMonths: return calendar.date(byAdding: .month, value: -6, to: now) ?? now
            case .oneYear: return calendar.date(byAdding: .year, value: -1, to: now) ?? now
            case .all: return Date.distantPast
            }
        }
    }

    private var shareText: String {
        generateReport()
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Text("🩺")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("Veteriner Paylaşım Raporu")
                                .font(.headline)
                            Text("\(pet.name) için sağlık özeti oluşturun")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Tarih Aralığı") {
                    Picker("Dönem", selection: $dateRange) {
                        ForEach(DateRange.allCases, id: \.self) { range in
                            Text(range.rawValue).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section("Dahil Edilecek Bilgiler") {
                    Toggle("⚖️ Kilo Kayıtları", isOn: $includeWeight)
                    Toggle("💉 Aşılar", isOn: $includeVaccines)
                    Toggle("💊 İlaçlar", isOn: $includeMedications)
                    Toggle("🏥 Veteriner Ziyaretleri", isOn: $includeVetVisits)
                    Toggle("🐾 Davranış Kayıtları", isOn: $includeBehavior)
                }

                Section {
                    // Preview
                    Text(shareText)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(15)
                } header: {
                    Text("Önizleme")
                } footer: {
                    Text("Rapor metin formatında paylaşılacaktır.")
                }

                Section {
                    ShareLink(item: shareText) {
                        Label("Raporu Paylaş", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .listRowBackground(Color.clear)
                }
            }
            .navigationTitle("Vet Paylaşım")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func generateReport() -> String {
        let cutoff = dateRange.date
        var lines: [String] = []

        lines.append("═══════════════════════════════════════")
        lines.append("🩺 SAĞLIK RAPORU — \(pet.name)")
        lines.append("═══════════════════════════════════════")
        lines.append("")
        lines.append("📋 Genel Bilgiler")
        lines.append("  Tür: \(pet.species.rawValue)")
        lines.append("  Irk: \(pet.breed)")
        lines.append("  Yaş: \(pet.age)")
        lines.append("  Cinsiyet: \(pet.sex.rawValue)")
        lines.append("  Kısırlaştırılmış: \(pet.isNeutered ? "Evet" : "Hayır")")
        if let weight = pet.latestWeight {
            lines.append("  Güncel Kilo: \(String(format: "%.1f", weight)) kg")
        }
        if !pet.allergies.isEmpty {
            lines.append("  ⚠️ Alerjiler: \(pet.allergies)")
        }
        if !pet.specialConditions.isEmpty {
            lines.append("  🩺 Özel Durumlar: \(pet.specialConditions)")
        }
        if !pet.microchipID.isEmpty {
            lines.append("  📡 Mikroçip: \(pet.microchipID)")
        }
        lines.append("")

        let df = DateFormatter()
        df.locale = Locale(identifier: "tr_TR")
        df.dateFormat = "dd.MM.yyyy"

        // Weight logs
        if includeWeight {
            let logs = pet.weightLogs.filter { $0.date >= cutoff }.sorted { $0.date > $1.date }
            if !logs.isEmpty {
                lines.append("⚖️ Kilo Geçmişi (\(logs.count) kayıt)")
                lines.append("───────────────────────────────────────")
                for log in logs.prefix(20) {
                    lines.append("  \(df.string(from: log.date)): \(String(format: "%.1f", log.weightKg)) kg \(log.notes.isEmpty ? "" : "– \(log.notes)")")
                }
                lines.append("")
            }
        }

        // Vaccines
        if includeVaccines {
            let records = pet.vaccineRecords.sorted { ($0.dueDate ?? $0.dateAdministered) > ($1.dueDate ?? $1.dateAdministered) }
            if !records.isEmpty {
                lines.append("💉 Aşı Kayıtları (\(records.count) adet)")
                lines.append("───────────────────────────────────────")
                for v in records {
                    let status = v.isOverdue ? "❌ GECİKMİŞ" : (v.isDueSoon ? "⚠️ Yaklaşıyor" : "✅")
                    lines.append("  \(v.name): Yapıldı \(df.string(from: v.dateAdministered)) | Sonraki: \(v.dueDate.map { df.string(from: $0) } ?? "–") \(status)")
                }
                lines.append("")
            }
        }

        // Medications
        if includeMedications {
            if !pet.medications.isEmpty {
                lines.append("💊 İlaçlar")
                lines.append("───────────────────────────────────────")
                for med in pet.medications {
                    let active = med.isActive ? "🟢 Aktif" : "⚪ Bitti"
                    lines.append("  \(med.name) \(med.dosage) (\(med.schedule.rawValue)) \(active)")
                    lines.append("    Başlangıç: \(df.string(from: med.startDate)) \(med.endDate.map { "→ \(df.string(from: $0))" } ?? "")")
                }
                lines.append("")
            }
        }

        // Vet visits
        if includeVetVisits {
            let visits = pet.vetVisits.filter { $0.date >= cutoff }.sorted { $0.date > $1.date }
            if !visits.isEmpty {
                lines.append("🏥 Veteriner Ziyaretleri (\(visits.count) adet)")
                lines.append("───────────────────────────────────────")
                for visit in visits.prefix(15) {
                    lines.append("  \(df.string(from: visit.date)): \(visit.reason)")
                    if !visit.diagnosis.isEmpty {
                        lines.append("    Tanı: \(visit.diagnosis)")
                    }
                    if !visit.notes.isEmpty {
                        lines.append("    Not: \(visit.notes)")
                    }
                }
                lines.append("")
            }
        }

        // Behavior logs
        if includeBehavior {
            let behaviors = pet.behaviorLogs.filter { $0.date >= cutoff }.sorted { $0.date > $1.date }
            if !behaviors.isEmpty {
                lines.append("🐾 Davranış Kayıtları (\(behaviors.count) adet)")
                lines.append("───────────────────────────────────────")
                for b in behaviors.prefix(10) {
                    lines.append("  \(df.string(from: b.date)): \(b.behaviorType.rawValue) (şiddet: \(b.severity)/5) \(b.notes)")
                }
                lines.append("")
            }
        }

        // Wellness Score
        let score = WellnessScoreEngine.calculate(for: pet)
        lines.append("📊 Wellness Skoru: \(score.overall)/100 (\(score.grade.rawValue))")
        lines.append("")
        lines.append("───────────────────────────────────────")
        lines.append("Rapor Tarihi: \(df.string(from: Date()))")
        lines.append("PetLog ile oluşturuldu")

        return lines.joined(separator: "\n")
    }
}
