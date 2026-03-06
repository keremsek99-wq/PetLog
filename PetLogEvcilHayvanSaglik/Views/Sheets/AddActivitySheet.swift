import SwiftUI
import SwiftData

struct AddActivitySheet: View {
    let store: PetStore
    @Environment(\.dismiss) private var dismiss
    @State private var activityType: ActivityType = .walk
    @State private var durationMinutes = 30
    @State private var notes = ""
    @State private var date = Date()
    @State private var saved = false

    private var pet: Pet? { store.selectedPet }

    // Only show relevant activities for the species
    private var availableTypes: [ActivityType] {
        guard let pet else { return ActivityType.allCases }
        return pet.relevantActivityTypes
    }

    private var activityEmoji: String {
        switch activityType {
        case .walk: return "🚶"
        case .play: return "🎾"
        case .training: return "🎓"
        case .grooming: return "✂️"
        case .potty: return "🚽"
        case .bath: return "🛁"
        case .nailTrim: return "💅"
        case .sleep: return "😴"
        case .other: return "📝"
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Emoji header
                    VStack(spacing: 8) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [PetOSColors.healthGreen.opacity(0.2), PetOSColors.healthGreen.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                            Text(activityEmoji)
                                .font(.largeTitle)
                        }
                        .animation(.spring(duration: 0.3), value: activityType)

                        if let pet {
                            Text("\(pet.name) aktivitesi")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.top, 8)

                    // Activity type chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Aktivite Tipi")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        LazyVGrid(columns: [
                            GridItem(.flexible()),
                            GridItem(.flexible()),
                            GridItem(.flexible())
                        ], spacing: 8) {
                            ForEach(availableTypes, id: \.self) { type in
                                Button {
                                    withAnimation(.spring(duration: 0.2)) {
                                        activityType = type
                                    }
                                } label: {
                                    VStack(spacing: 4) {
                                        Image(systemName: type.icon)
                                            .font(.title3)
                                            .foregroundStyle(activityType == type ? .white : PetOSColors.healthGreen)
                                        Text(type.rawValue)
                                            .font(.caption2)
                                            .foregroundStyle(activityType == type ? .white : .primary)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 10)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(activityType == type
                                                  ? PetOSColors.healthGreen
                                                  : Color(.secondarySystemGroupedBackground))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .sensoryFeedback(.selection, trigger: activityType)
                    }

                    // Duration (except potty)
                    if activityType != .potty {
                        VStack(spacing: 8) {
                            Text("Süre")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.leading, 4)

                            HStack {
                                Button {
                                    if durationMinutes > 5 {
                                        durationMinutes -= 5
                                    }
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(PetOSColors.healthGreen)
                                }

                                Spacer()

                                VStack(spacing: 2) {
                                    Text("\(durationMinutes)")
                                        .font(.system(.title, design: .rounded, weight: .bold))
                                        .contentTransition(.numericText())
                                    Text("dakika")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                Button {
                                    if durationMinutes < 480 {
                                        durationMinutes += 5
                                    }
                                } label: {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                        .foregroundStyle(PetOSColors.healthGreen)
                                }
                            }
                            .padding(16)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(Color(.secondarySystemGroupedBackground))
                            )
                            .sensoryFeedback(.selection, trigger: durationMinutes)
                        }
                    }

                    // Date & Notes
                    VStack(spacing: 12) {
                        DatePicker("Tarih", selection: $date, displayedComponents: [.date, .hourAndMinute])
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        TextField("Opsiyonel not...", text: $notes, axis: .vertical)
                            .lineLimit(3)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Aktivite Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
            .sensoryFeedback(.success, trigger: saved)
        }
    }

    private func save() {
        guard let pet = store.selectedPet else { return }
        store.addActivityLog(to: pet, activityType: activityType, durationMinutes: durationMinutes, notes: notes, date: date)
        saved = true
        dismiss()
    }
}
