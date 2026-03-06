import SwiftUI
import SwiftData

struct AddBehaviorSheet: View {
    let store: PetStore
    @Environment(\.dismiss) private var dismiss
    @State private var behaviorType: BehaviorType = .barking
    @State private var severity = 3
    @State private var notes = ""
    @State private var date = Date()
    @State private var saved = false

    private let severityLabels = ["Çok hafif", "Hafif", "Orta", "Şiddetli", "Çok şiddetli"]
    private let severityEmojis = ["😊", "🙂", "😐", "😟", "😰"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Dynamic emoji header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [severityColor(severity).opacity(0.2), severityColor(severity).opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                            Text(severityEmojis[severity - 1])
                                .font(.largeTitle)
                        }
                        .animation(.spring(duration: 0.3), value: severity)

                        Text(severityLabels[severity - 1])
                            .font(.caption.weight(.medium))
                            .foregroundStyle(severityColor(severity))
                            .contentTransition(.numericText())
                    }
                    .padding(.top, 8)

                    // Behavior type selection
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Davranış / Belirti")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(BehaviorType.allCases, id: \.self) { type in
                                Button {
                                    withAnimation(.spring(duration: 0.2)) {
                                        behaviorType = type
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: type.icon)
                                            .font(.title3)
                                            .foregroundStyle(behaviorType == type ? .white : .orange)
                                        Text(type.rawValue)
                                            .font(.caption2)
                                            .foregroundStyle(behaviorType == type ? .white : .primary)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(behaviorType == type
                                                  ? Color.orange
                                                  : Color(.secondarySystemGroupedBackground))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    // Severity slider
                    VStack(spacing: 12) {
                        Text("Şiddet")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 4)

                        HStack(spacing: 0) {
                            ForEach(1...5, id: \.self) { level in
                                Button {
                                    withAnimation(.spring(duration: 0.2)) {
                                        severity = level
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        ZStack {
                                            Circle()
                                                .fill(level <= severity ? severityColor(level) : Color(.systemGray5))
                                                .frame(width: 40, height: 40)
                                            Text(severityEmojis[level - 1])
                                                .font(.subheadline)
                                        }
                                        Text("\(level)")
                                            .font(.caption2.weight(.bold))
                                            .foregroundStyle(level <= severity ? severityColor(level) : .secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .sensoryFeedback(.selection, trigger: severity)
                    }
                    .padding(14)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color(.secondarySystemGroupedBackground))
                    )

                    // Date & Notes
                    VStack(spacing: 12) {
                        DatePicker("Tarih", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        TextField("Detay ekleyin...", text: $notes, axis: .vertical)
                            .lineLimit(3)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))
                    }

                    // Vet tip
                    HStack(spacing: 10) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Bu kayıtları veteriner ziyaretinizde gösterebilirsiniz.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.blue.opacity(0.06))
                    )
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Davranış Kaydet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                        .fontWeight(.semibold)
                }
            }
            .sensoryFeedback(.success, trigger: saved)
        }
    }

    private func severityColor(_ level: Int) -> Color {
        switch level {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .gray
        }
    }

    private func save() {
        guard let pet = store.selectedPet else { return }
        store.addBehaviorLog(to: pet, behaviorType: behaviorType, severity: severity, notes: notes, date: date)
        saved = true
        dismiss()
    }
}

struct BehaviorHistoryView: View {
    let pet: Pet

    private var sortedLogs: [BehaviorLog] {
        pet.behaviorLogs.sorted { $0.date > $1.date }
    }

    private var recentSymptoms: [(BehaviorType, Int)] {
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let recent = pet.behaviorLogs.filter { $0.date >= thirtyDaysAgo }
        var counts: [BehaviorType: Int] = [:]
        for log in recent {
            counts[log.behaviorType, default: 0] += 1
        }
        return counts.sorted { $0.value > $1.value }
    }

    var body: some View {
        List {
            if !recentSymptoms.isEmpty {
                Section("Son 30 Gün Özeti") {
                    ForEach(recentSymptoms, id: \.0) { type, count in
                        HStack {
                            Image(systemName: type.icon)
                                .foregroundStyle(.orange)
                                .frame(width: 24)
                            Text(type.rawValue)
                                .font(.subheadline)
                            Spacer()
                            Text("\(count)x")
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(count >= 5 ? .red : .secondary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(count >= 5 ? Color.red.opacity(0.1) : Color.clear)
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Section("Tüm Kayıtlar") {
                if sortedLogs.isEmpty {
                    Text("Henüz davranış kaydı yok")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(sortedLogs, id: \.id) { log in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: log.behaviorType.icon)
                                    .foregroundStyle(.orange)
                                Text(log.behaviorType.rawValue)
                                    .font(.subheadline.weight(.medium))
                                Spacer()
                                HStack(spacing: 2) {
                                    ForEach(1...5, id: \.self) { i in
                                        Circle()
                                            .fill(i <= log.severity ? severityColor(i) : Color(.systemGray5))
                                            .frame(width: 8, height: 8)
                                    }
                                }
                            }
                            Text(log.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            if !log.notes.isEmpty {
                                Text(log.notes)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
        }
        .navigationTitle("Davranış Geçmişi")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func severityColor(_ level: Int) -> Color {
        switch level {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4: return .red
        case 5: return .purple
        default: return .gray
        }
    }
}
