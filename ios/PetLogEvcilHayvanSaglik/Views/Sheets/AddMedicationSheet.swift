import SwiftUI

struct AddMedicationSheet: View {
    let store: PetStore
    let pet: Pet

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var dosage: String = ""
    @State private var schedule: MedicationSchedule = .daily
    @State private var startDate: Date = Date()
    @State private var hasEndDate: Bool = false
    @State private var endDate: Date = Date()
    @State private var notes: String = ""
    @State private var saved = false

    private var scheduleEmoji: String {
        switch schedule {
        case .daily: return "📅"
        case .twiceDaily: return "🔄"
        case .weekly: return "📆"
        case .monthly: return "🗓️"
        case .asNeeded: return "⏰"
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
                                        colors: [PetOSColors.accent.opacity(0.2), PetOSColors.accent.opacity(0.05)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 64, height: 64)
                            Text("💊")
                                .font(.largeTitle)
                        }
                        Text("\(pet.name) ilaç takibi")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Medication name & dosage
                    VStack(spacing: 12) {
                        TextField("İlaç Adı", text: $name)
                            .font(.body.weight(.medium))
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        TextField("Doz (ör. 10mg)", text: $dosage)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))
                    }

                    // Schedule chips
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Sıklık")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        HStack(spacing: 6) {
                            ForEach(MedicationSchedule.allCases, id: \.self) { s in
                                Button {
                                    withAnimation(.spring(duration: 0.2)) {
                                        schedule = s
                                    }
                                } label: {
                                    VStack(spacing: 3) {
                                        Text(scheduleEmojiFor(s))
                                            .font(.subheadline)
                                        Text(s.rawValue)
                                            .font(.system(size: 9))
                                            .foregroundStyle(schedule == s ? .white : .primary)
                                            .lineLimit(1)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(schedule == s
                                                  ? PetOSColors.accent
                                                  : Color(.secondarySystemGroupedBackground))
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .sensoryFeedback(.selection, trigger: schedule)
                    }

                    // Dates
                    VStack(spacing: 12) {
                        DatePicker("Başlangıç Tarihi", selection: $startDate, displayedComponents: .date)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))

                        Toggle(isOn: $hasEndDate.animation(.spring(duration: 0.3))) {
                            HStack(spacing: 8) {
                                Image(systemName: "calendar.badge.checkmark")
                                    .foregroundStyle(PetOSColors.healthGreen)
                                Text("Bitiş Tarihi Var")
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))

                        if hasEndDate {
                            DatePicker("Bitiş Tarihi", selection: $endDate, in: startDate..., displayedComponents: .date)
                                .padding(12)
                                .background(Color(.secondarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 12))
                                .transition(.asymmetric(
                                    insertion: .move(edge: .top).combined(with: .opacity),
                                    removal: .opacity
                                ))
                        }
                    }

                    // Notes
                    TextField("İsteğe bağlı notlar", text: $notes, axis: .vertical)
                        .lineLimit(3)
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("İlaç Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        save()
                    }
                    .disabled(name.isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .sensoryFeedback(.success, trigger: saved)
        }
    }

    private func scheduleEmojiFor(_ s: MedicationSchedule) -> String {
        switch s {
        case .daily: return "📅"
        case .twiceDaily: return "🔄"
        case .weekly: return "📆"
        case .monthly: return "🗓️"
        case .asNeeded: return "⏰"
        }
    }

    private func save() {
        store.addMedication(to: pet, name: name, dosage: dosage, schedule: schedule, startDate: startDate, endDate: hasEndDate ? endDate : nil, notes: notes)
        saved = true
        dismiss()
    }
}
