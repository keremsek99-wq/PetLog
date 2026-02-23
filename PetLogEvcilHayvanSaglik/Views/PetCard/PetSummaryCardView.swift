import SwiftUI
import Charts

struct PetSummaryCardView: View {
    let pet: Pet
    let store: PetStore

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                headerSection
                Divider().padding(.horizontal)
                infoGrid
                Divider().padding(.horizontal)
                weightSection
                Divider().padding(.horizontal)
                vaccineSection
                Divider().padding(.horizontal)
                medicationSection
                Divider().padding(.horizontal)
                recentVisitsSection
                Divider().padding(.horizontal)
                spendingSummarySection
                disclaimerSection
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Pet Özeti")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                ShareLink(item: generateShareText()) {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }

    private var headerSection: some View {
        VStack(spacing: 14) {
            ZStack {
                if let photoData = pet.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 88, height: 88)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.blue.opacity(0.2), lineWidth: 2))
                } else {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue.opacity(0.15), .blue.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 88, height: 88)
                    Image(systemName: pet.species.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                }
            }

            VStack(spacing: 4) {
                Text(pet.name)
                    .font(.title.bold())
                HStack(spacing: 8) {
                    if pet.species != .unspecified {
                        Text(pet.species.rawValue)
                    }
                    if !pet.breed.isEmpty {
                        Text("·").foregroundStyle(.tertiary)
                        Text(pet.breed)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Text(pet.age)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
            }
        }
        .padding(.vertical, 24)
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var infoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            infoTile(icon: "scalemass.fill", color: .green, label: "Güncel Kilo",
                     value: pet.latestWeight.map { String(format: "%.1f kg", $0) } ?? "—")
            infoTile(icon: "calendar", color: .blue, label: "Doğum Tarihi",
                     value: pet.birthdate.formatted(date: .abbreviated, time: .omitted))
            infoTile(icon: "heart.fill", color: .pink, label: "Cinsiyet",
                     value: pet.sex.rawValue)
            infoTile(icon: "scissors", color: .orange, label: "Kısırlaştırma",
                     value: pet.isNeutered ? "Evet" : "Hayır")
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func infoTile(icon: String, color: Color, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.12))
                .clipShape(.rect(cornerRadius: 6))
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline.weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.tertiarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 10))
    }

    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardSectionTitle("Kilo Geçmişi", icon: "chart.line.uptrend.xyaxis", color: .green)

            let sorted = pet.weightLogs.sorted { $0.date < $1.date }
            if sorted.count >= 2 {
                Chart(sorted.suffix(10), id: \.id) { log in
                    LineMark(x: .value("Tarih", log.date), y: .value("Kilo", log.weightKg))
                        .foregroundStyle(.green)
                        .interpolationMethod(.catmullRom)
                    PointMark(x: .value("Tarih", log.date), y: .value("Kilo", log.weightKg))
                        .foregroundStyle(.green)
                        .symbolSize(20)
                }
                .chartYScale(domain: weightDomain(sorted))
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 3)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 140)
            } else if let weight = pet.latestWeight {
                HStack {
                    Text(String(format: "%.1f kg", weight))
                        .font(.title3.weight(.bold))
                    Spacer()
                    Text("tek kayıt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Henüz kilo kaydı yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func weightDomain(_ logs: [WeightLog]) -> ClosedRange<Double> {
        let weights = logs.map(\.weightKg)
        let minW = (weights.min() ?? 0) * 0.95
        let maxW = (weights.max() ?? 10) * 1.05
        return minW...maxW
    }

    private var vaccineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardSectionTitle("Son Aşılar", icon: "syringe.fill", color: .purple)

            let recent = Array(pet.vaccineRecords.sorted { $0.dateAdministered > $1.dateAdministered }.prefix(5))
            if recent.isEmpty {
                Text("Aşı kaydı yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recent, id: \.id) { vaccine in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(vaccineColor(vaccine).opacity(0.15))
                            .frame(width: 8, height: 8)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(vaccine.name)
                                .font(.subheadline.weight(.medium))
                            Text(vaccine.dateAdministered.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if let due = vaccine.dueDate {
                            Text(vaccine.isOverdue ? "Gecikmiş" : due.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(vaccine.isOverdue ? .red : .secondary)
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func vaccineColor(_ vaccine: VaccineRecord) -> Color {
        if vaccine.isOverdue { return .red }
        if vaccine.isDueSoon { return .orange }
        return .green
    }

    private var medicationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardSectionTitle("Aktif İlaçlar", icon: "pills.fill", color: .blue)

            let active = pet.activeMedications
            if active.isEmpty {
                Text("Aktif ilaç yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(active, id: \.id) { med in
                    HStack(spacing: 10) {
                        Image(systemName: "pills.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                            .frame(width: 24, height: 24)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 1) {
                            Text(med.name)
                                .font(.subheadline.weight(.medium))
                            if !med.dosage.isEmpty {
                                Text(med.dosage)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(med.schedule.rawValue)
                            .font(.caption2)
                            .foregroundStyle(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.08))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var recentVisitsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardSectionTitle("Son Veteriner Ziyaretleri", icon: "cross.case.fill", color: .red)

            let recent = Array(pet.vetVisits.sorted { $0.date > $1.date }.prefix(3))
            if recent.isEmpty {
                Text("Veteriner ziyareti yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recent, id: \.id) { visit in
                    HStack {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(visit.reason)
                                .font(.subheadline.weight(.medium))
                            Text(visit.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        if visit.cost > 0 {
                            Text(visit.cost.formatted(.currency(code: "TRY")))
                                .font(.caption.weight(.semibold))
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var spendingSummarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            cardSectionTitle("Harcama Özeti", icon: "turkishlirasign.circle.fill", color: .orange)

            let monthly = store.monthlySpending(for: pet)
            let annual = store.annualSpending(for: pet)

            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bu Ay")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(monthly.formatted(.currency(code: "TRY")))
                        .font(.headline)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Bu Yıl")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(annual.formatted(.currency(code: "TRY")))
                        .font(.headline)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
    }

    private var disclaimerSection: some View {
        VStack(spacing: 8) {
            Image(systemName: "info.circle")
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("Bu özet yalnızca bilgi amaçlıdır. Tıbbi kararlarda veterinerinize danışın.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            Text("PetLog · \(Date().formatted(date: .abbreviated, time: .shortened))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(20)
    }

    private func cardSectionTitle(_ title: String, icon: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.subheadline.weight(.medium))
                .foregroundStyle(color)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
    }

    private func generateShareText() -> String {
        var text = "PetLog - Pet Özeti\n"
        text += "━━━━━━━━━━━━━━━━━\n\n"
        text += "\(pet.name)\n"
        text += "Tür: \(pet.species.rawValue)"
        if !pet.breed.isEmpty { text += " · \(pet.breed)" }
        text += "\nYaş: \(pet.age)\n"
        text += "Cinsiyet: \(pet.sex.rawValue)\n"
        text += "Kısırlaştırılmış: \(pet.isNeutered ? "Evet" : "Hayır")\n\n"

        if let weight = pet.latestWeight {
            text += "Güncel Kilo: \(String(format: "%.1f", weight)) kg\n\n"
        }

        let vaccines = Array(pet.vaccineRecords.sorted { $0.dateAdministered > $1.dateAdministered }.prefix(5))
        if !vaccines.isEmpty {
            text += "Son Aşılar:\n"
            for v in vaccines {
                text += "  - \(v.name) (\(v.dateAdministered.formatted(date: .abbreviated, time: .omitted)))\n"
            }
            text += "\n"
        }

        let meds = pet.activeMedications
        if !meds.isEmpty {
            text += "Aktif İlaçlar:\n"
            for m in meds {
                text += "  - \(m.name) \(m.dosage) (\(m.schedule.rawValue))\n"
            }
            text += "\n"
        }

        text += "━━━━━━━━━━━━━━━━━\n"
        text += "PetLog · \(Date().formatted(date: .abbreviated, time: .shortened))\n"
        text += "Bu özet tıbbi tavsiye niteliği taşımaz."

        return text
    }
}
