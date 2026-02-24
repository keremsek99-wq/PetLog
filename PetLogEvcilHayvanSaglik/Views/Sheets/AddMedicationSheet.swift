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

    var body: some View {
        NavigationStack {
            Form {
                Section("İlaç") {
                    TextField("İlaç Adı", text: $name)
                    TextField("Doz (ör. 10mg)", text: $dosage)
                }

                Section("Takvim") {
                    Picker("Sıklık", selection: $schedule) {
                        ForEach(MedicationSchedule.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    DatePicker("Başlangıç Tarihi", selection: $startDate, displayedComponents: .date)
                    Toggle("Bitiş Tarihi Var", isOn: $hasEndDate)
                    if hasEndDate {
                        DatePicker("Bitiş Tarihi", selection: $endDate, in: startDate..., displayedComponents: .date)
                    }
                }

                Section("Notlar") {
                    TextField("İsteğe bağlı notlar", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
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

    private func save() {
        store.addMedication(to: pet, name: name, dosage: dosage, schedule: schedule, startDate: startDate, endDate: hasEndDate ? endDate : nil, notes: notes)
        saved = true
        dismiss()
    }
}
