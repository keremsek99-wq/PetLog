import SwiftUI

/// A view that prepares a summary of the pet's recent health data
/// for sharing with a veterinarian. Consolidates symptoms, behaviors,
/// medications, weight changes, and feeding patterns.
struct VetPrepView: View {
    let pet: Pet
    let store: PetStore
    
    @State private var selectedDays = 14
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    petSummaryHeader
                    
                    // Time range picker
                    timeRangePicker
                    
                    // Symptoms section
                    symptomsSection
                    
                    // Medications
                    medicationsSection
                    
                    // Weight trend
                    weightSection
                    
                    // Feeding summary
                    feedingSection
                    
                    // Activity summary
                    activitySection
                    
                    // Recent vet visits
                    recentVetVisitsSection
                }
                .padding()
            }
            .navigationTitle("Veteriner Hazırlık")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    // MARK: - Pet Summary Header
    
    private var petSummaryHeader: some View {
        HStack(spacing: 14) {
            if let photoData = pet.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(Circle())
            } else {
                Text(pet.emoji)
                    .font(.largeTitle)
                    .frame(width: 56, height: 56)
                    .background(pet.speciesColor.opacity(0.15))
                    .clipShape(Circle())
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(pet.name)
                    .font(.title3.weight(.bold))
                HStack(spacing: 8) {
                    Text(pet.species.rawValue)
                    if !pet.breed.isEmpty {
                        Text("·").foregroundStyle(.tertiary)
                        Text(pet.breed)
                    }
                    Text("·").foregroundStyle(.tertiary)
                    Text(pet.age)
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            
            if pet.isSickMode {
                Text("🔴 Takip Altında")
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.red)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Capsule())
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
    
    // MARK: - Time Range
    
    private var timeRangePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Zaman Aralığı")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            
            Picker("Süre", selection: $selectedDays) {
                Text("7 gün").tag(7)
                Text("14 gün").tag(14)
                Text("30 gün").tag(30)
            }
            .pickerStyle(.segmented)
        }
    }
    
    // MARK: - Symptoms
    
    @ViewBuilder
    private var symptomsSection: some View {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedDays, to: Date()) ?? Date()
        let recentBehaviors = pet.behaviorLogs
            .filter { $0.date >= cutoff }
            .sorted { $0.date > $1.date }
        
        VetPrepSection(title: "Semptomlar & Davranışlar", icon: "exclamationmark.triangle.fill", count: recentBehaviors.count) {
            if recentBehaviors.isEmpty {
                Text("Bu dönemde kayıt yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentBehaviors, id: \.id) { log in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(severityColor(log.severity))
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            HStack {
                                Text(log.behaviorType.rawValue)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                Text("Şiddet: \(log.severity)/5")
                                    .font(.caption)
                                    .foregroundStyle(severityColor(log.severity))
                            }
                            Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                            if !log.notes.isEmpty {
                                Text(log.notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(2)
                            }
                        }
                    }
                    if log.id != recentBehaviors.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
    
    // MARK: - Medications
    
    @ViewBuilder
    private var medicationsSection: some View {
        let activeMeds = pet.activeMedications
        
        VetPrepSection(title: "Aktif İlaçlar", icon: "pills.fill", count: activeMeds.count) {
            if activeMeds.isEmpty {
                Text("Aktif ilaç yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(activeMeds, id: \.id) { med in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(med.name)
                                .font(.subheadline.weight(.medium))
                            if !med.dosage.isEmpty {
                                Text("Doz: \(med.dosage)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text("Başlangıç: \(med.startDate.formatted(date: .abbreviated, time: .omitted))")
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                        Text(med.schedule.rawValue)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 3)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    if med.id != activeMeds.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
    
    // MARK: - Weight
    
    @ViewBuilder
    private var weightSection: some View {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedDays, to: Date()) ?? Date()
        let recentWeights = pet.weightLogs
            .filter { $0.date >= cutoff }
            .sorted { $0.date > $1.date }
        
        VetPrepSection(title: "Kilo Takibi", icon: "scalemass.fill", count: recentWeights.count) {
            if recentWeights.isEmpty {
                if let latest = pet.latestWeight {
                    Text("Son kilo: \(String(format: "%.1f", latest)) kg (bu dönemden önce)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Kilo kaydı yok")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(recentWeights, id: \.id) { weight in
                    HStack {
                        Text(weight.date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text("\(String(format: "%.1f", weight.weightKg)) kg")
                            .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }
    
    // MARK: - Feeding
    
    @ViewBuilder
    private var feedingSection: some View {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedDays, to: Date()) ?? Date()
        let recentFeedings = pet.feedingLogs.filter { $0.date >= cutoff }
        let mealCounts = Dictionary(grouping: recentFeedings, by: { $0.mealType }).mapValues(\.count)
        
        VetPrepSection(title: "Beslenme Özeti", icon: "fork.knife", count: recentFeedings.count) {
            if recentFeedings.isEmpty {
                Text("Bu dönemde beslenme kaydı yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack(spacing: 16) {
                    ForEach(Array(mealCounts.sorted { $0.value > $1.value }), id: \.key) { mealType, count in
                        VStack(spacing: 4) {
                            Text("\(count)")
                                .font(.title3.weight(.bold))
                            Text(mealType.rawValue)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                }
                
                Text("Günlük ortalama: \(String(format: "%.1f", selectedDays > 0 ? Double(recentFeedings.count) / Double(selectedDays) : 0)) öğün")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    // MARK: - Activity
    
    @ViewBuilder
    private var activitySection: some View {
        let cutoff = Calendar.current.date(byAdding: .day, value: -selectedDays, to: Date()) ?? Date()
        let recentActivities = pet.activityLogs.filter { $0.date >= cutoff }
        let totalMinutes = recentActivities.reduce(0) { $0 + $1.durationMinutes }
        
        VetPrepSection(title: "Aktivite Özeti", icon: "flame.fill", count: recentActivities.count) {
            if recentActivities.isEmpty {
                Text("Bu dönemde aktivite kaydı yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Toplam: \(recentActivities.count) aktivite, \(totalMinutes) dk")
                            .font(.subheadline)
                        Text("Günlük ortalama: \(String(format: "%.0f", selectedDays > 0 ? Double(totalMinutes) / Double(selectedDays) : 0)) dk")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
            }
        }
    }
    
    // MARK: - Recent Vet Visits
    
    @ViewBuilder
    private var recentVetVisitsSection: some View {
        let cutoff = Calendar.current.date(byAdding: .month, value: -3, to: Date()) ?? Date()
        let recentVisits = pet.vetVisits
            .filter { $0.date >= cutoff }
            .sorted { $0.date > $1.date }
        
        VetPrepSection(title: "Son Vet Ziyaretleri (3 ay)", icon: "cross.case.fill", count: recentVisits.count) {
            if recentVisits.isEmpty {
                Text("Son 3 ayda veteriner ziyareti yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentVisits, id: \.id) { visit in
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(visit.reason)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(visit.date.formatted(date: .abbreviated, time: .omitted))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        if !visit.diagnosis.isEmpty {
                            Text("Tanı: \(visit.diagnosis)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if visit.id != recentVisits.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    
    private func severityColor(_ severity: Int) -> Color {
        switch severity {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4...5: return .red
        default: return .gray
        }
    }
}

// MARK: - VetPrep Section Component

struct VetPrepSection<Content: View>: View {
    let title: String
    let icon: String
    let count: Int
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(.secondary)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(count)")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
            }
            
            content
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
}
