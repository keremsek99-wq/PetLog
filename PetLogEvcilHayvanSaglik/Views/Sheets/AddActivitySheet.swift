import SwiftUI
import SwiftData

struct AddActivitySheet: View {
    let store: PetStore
    @Environment(\.dismiss) private var dismiss
    @State private var activityType: ActivityType = .walk
    @State private var durationMinutes = 30
    @State private var notes = ""
    @State private var date = Date()

    var body: some View {
        NavigationStack {
            Form {
                Section("Aktivite Tipi") {
                    Picker("Tip", selection: $activityType) {
                        ForEach(ActivityType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.navigationLink)
                }

                if activityType != .potty {
                    Section("Süre") {
                        Stepper("\(durationMinutes) dakika", value: $durationMinutes, in: 1...480, step: 5)
                    }
                }

                Section("Tarih") {
                    DatePicker("Tarih", selection: $date, displayedComponents: [.date, .hourAndMinute])
                }

                Section("Notlar") {
                    TextField("Opsiyonel not...", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
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
                }
            }
        }
    }

    private func save() {
        guard let pet = store.selectedPet else { return }
        let log = ActivityLog(activityType: activityType, durationMinutes: durationMinutes, notes: notes, date: date)
        log.pet = pet
        store.modelContext.insert(log)
        dismiss()
    }
}
