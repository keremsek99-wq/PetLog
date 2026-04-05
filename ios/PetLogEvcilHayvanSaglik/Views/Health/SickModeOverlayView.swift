import SwiftUI

/// Full-screen overlay that appears when a pet is in Sick Mode.
/// Shows critical health info, active symptoms, medication schedule,
/// and provides quick access to vet prep and symptom logging.
struct SickModeOverlayView: View {
    let pet: Pet
    let store: PetStore
    let premiumManager: PremiumManager
    
    @State private var showVetPrep = false
    @State private var showAddBehavior = false
    @State private var showSymptomTimeline = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Red gradient background
                LinearGradient(
                    colors: [Color.red.opacity(0.08), Color(.systemBackground)],
                    startPoint: .top,
                    endPoint: .center
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Sick mode header with pulse
                        sickModeHeader
                        
                        // Active symptoms
                        activeSymptoms
                        
                        // Active medications
                        activeMedications
                        
                        // Quick actions
                        quickActions
                        
                        // Recent timeline preview
                        recentTimelinePreview
                    }
                    .padding()
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("🔴 Takip Modu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Kapat") { dismiss() }
                }
            }
            .sheet(isPresented: $showVetPrep) {
                VetPrepView(pet: pet, store: store)
            }
            .sheet(isPresented: $showAddBehavior) {
                AddBehaviorSheet(store: store)
            }
            .sheet(isPresented: $showSymptomTimeline) {
                NavigationStack {
                    SymptomTimelineView(pet: pet)
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button("Kapat") { showSymptomTimeline = false }
                            }
                        }
                }
            }
        }
    }
    
    // MARK: - Sick Mode Header
    
    private var sickModeHeader: some View {
        VStack(spacing: 12) {
            // Pet photo with red pulse ring
            ZStack {
                Circle()
                    .stroke(Color.red.opacity(0.3), lineWidth: 4)
                    .frame(width: 90, height: 90)
                    .modifier(PulseAnimation())
                
                if let photoData = pet.photoData, let uiImage = UIImage(data: photoData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 76, height: 76)
                        .clipShape(Circle())
                } else {
                    Text(pet.emoji)
                        .font(.system(size: 36))
                        .frame(width: 76, height: 76)
                        .background(Color.red.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Text("\(pet.name) Takip Altında")
                .font(.title3.weight(.bold))
            
            // Sick mode reason
            Text(sickModeReason)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 10)
    }
    
    private var sickModeReason: String {
        var reasons: [String] = []
        if !pet.activeMedications.isEmpty {
            reasons.append("\(pet.activeMedications.count) aktif ilaç")
        }
        let twoWeeksAgo = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
        let recentVets = pet.vetVisits.filter { $0.date >= twoWeeksAgo }.count
        if recentVets > 0 {
            reasons.append("Son 2 haftada \(recentVets) vet ziyareti")
        }
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let highSeverity = pet.behaviorLogs.filter { $0.date >= sevenDaysAgo && $0.severity >= 4 }.count
        if highSeverity > 0 {
            reasons.append("\(highSeverity) yüksek şiddetli semptom")
        }
        return reasons.isEmpty ? "Takip altında" : reasons.joined(separator: " • ")
    }
    
    // MARK: - Active Symptoms
    
    @ViewBuilder
    private var activeSymptoms: some View {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentSymptoms = pet.behaviorLogs
            .filter { $0.date >= sevenDaysAgo }
            .sorted { $0.date > $1.date }
        
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("⚠️ Son 7 Gün Semptomlar")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(recentSymptoms.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(recentSymptoms.isEmpty ? Color.green : Color.red)
                    )
            }
            
            if recentSymptoms.isEmpty {
                Text("Son 7 günde semptom kaydı yok ✓")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(recentSymptoms.prefix(5), id: \.id) { log in
                    HStack(spacing: 10) {
                        Circle()
                            .fill(severityColor(log.severity))
                            .frame(width: 8, height: 8)
                        
                        VStack(alignment: .leading, spacing: 1) {
                            HStack {
                                Text(log.behaviorType.rawValue)
                                    .font(.subheadline.weight(.medium))
                                Text("(\(log.severity)/5)")
                                    .font(.caption2)
                                    .foregroundStyle(severityColor(log.severity))
                            }
                            Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        Spacer()
                    }
                }
                
                if recentSymptoms.count > 5 {
                    Button {
                        showSymptomTimeline = true
                    } label: {
                        Text("Tüm semptomları gör (\(recentSymptoms.count))")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(.red)
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
    
    // MARK: - Active Medications
    
    @ViewBuilder
    private var activeMedications: some View {
        let meds = pet.activeMedications
        
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("💊 Aktif İlaçlar")
                    .font(.subheadline.weight(.semibold))
                Spacer()
                Text("\(meds.count)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule().fill(meds.isEmpty ? Color.green : Color.blue)
                    )
            }
            
            if meds.isEmpty {
                Text("Aktif ilaç yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(meds, id: \.id) { med in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(med.name)
                                .font(.subheadline.weight(.medium))
                            if !med.dosage.isEmpty {
                                Text(med.dosage)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(med.schedule.rawValue)
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                            if let endDate = med.endDate {
                                let daysLeft = Calendar.current.dateComponents([.day], from: Date(), to: endDate).day ?? 0
                                Text("\(max(0, daysLeft)) gün kaldı")
                                    .font(.caption2)
                                    .foregroundStyle(daysLeft <= 3 ? .red : .secondary)
                            }
                        }
                    }
                    if med.id != meds.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
    
    // MARK: - Quick Actions
    
    private var quickActions: some View {
        HStack(spacing: 12) {
            Button {
                showAddBehavior = true
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                    Text("Semptom Kaydet")
                        .font(.caption2.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red.opacity(0.08))
                .clipShape(.rect(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
            Button {
                showVetPrep = true
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.title2)
                        .foregroundStyle(.green)
                    Text("Vet Hazırlık")
                        .font(.caption2.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.green.opacity(0.08))
                .clipShape(.rect(cornerRadius: 12))
            }
            .buttonStyle(.plain)
            
            Button {
                showSymptomTimeline = true
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2)
                        .foregroundStyle(.orange)
                    Text("Zaman Çizelgesi")
                        .font(.caption2.weight(.medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.orange.opacity(0.08))
                .clipShape(.rect(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }
    
    // MARK: - Recent Timeline Preview
    
    @ViewBuilder
    private var recentTimelinePreview: some View {
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()
        let recentBehaviors = pet.behaviorLogs
            .filter { $0.date >= threeDaysAgo }
            .sorted { $0.date > $1.date }
        
        if !recentBehaviors.isEmpty {
            VStack(alignment: .leading, spacing: 10) {
                Text("📋 Son 3 Gün")
                    .font(.subheadline.weight(.semibold))
                
                ForEach(recentBehaviors.prefix(3), id: \.id) { log in
                    HStack(spacing: 10) {
                        VStack(spacing: 2) {
                            Text(log.date.formatted(.dateTime.day().month(.abbreviated)))
                                .font(.caption2.weight(.semibold))
                            Text(log.date.formatted(.dateTime.hour().minute()))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        .frame(width: 50)
                        
                        Rectangle()
                            .fill(severityColor(log.severity))
                            .frame(width: 3, height: 30)
                            .clipShape(Capsule())
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(log.behaviorType.rawValue)
                                .font(.subheadline.weight(.medium))
                            if !log.notes.isEmpty {
                                Text(log.notes)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        Spacer()
                    }
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 14))
        }
    }
    
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

// MARK: - Pulse Animation Modifier

struct PulseAnimation: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.08 : 1.0)
            .opacity(isPulsing ? 0.6 : 1.0)
            .animation(
                .easeInOut(duration: 1.2)
                .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear { isPulsing = true }
            .onDisappear { isPulsing = false }
    }
}
