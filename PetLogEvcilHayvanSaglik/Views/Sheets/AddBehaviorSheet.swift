import SwiftUI

struct AddBehaviorSheet: View {
    let store: PetStore
    @Environment(\.dismiss) private var dismiss
    @State private var behaviorType: BehaviorType = .barking
    @State private var severity = 3
    @State private var notes = ""
    @State private var date = Date()

    private let severityLabels = ["Çok hafif", "Hafif", "Orta", "Şiddetli", "Çok şiddetli"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Davranış / Belirti") {
                    Picker("Tip", selection: $behaviorType) {
                        ForEach(BehaviorType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                Section("Şiddet") {
                    VStack(spacing: 8) {
                        HStack {
                            ForEach(1...5, id: \.self) { level in
                                Button {
                                    severity = level
                                } label: {
                                    Circle()
                                        .fill(level <= severity ? severityColor(level) : Color(.systemGray5))
                                        .frame(width: 36, height: 36)
                                        .overlay {
                                            Text("\(level)")
                                                .font(.caption.weight(.bold))
                                                .foregroundStyle(level <= severity ? .white : .secondary)
                                        }
                                }
                                .buttonStyle(.plain)
                                if level < 5 { Spacer() }
                            }
                        }
                        Text(severityLabels[severity - 1])
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Tarih") {
                    DatePicker("Tarih", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Notlar") {
                    TextField("Detay ekleyin...", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }

                Section {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text("Bu kayıtları veteriner ziyaretinizde gösterebilirsiniz.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Davranış Kaydet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") { save() }
                }
            }
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
        let log = BehaviorLog(behaviorType: behaviorType, severity: severity, notes: notes, date: date)
        log.pet = pet
        store.modelContext.insert(log)
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
