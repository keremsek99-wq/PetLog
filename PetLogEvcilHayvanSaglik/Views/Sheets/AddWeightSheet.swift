import SwiftUI

struct AddWeightSheet: View {
    let store: PetStore
    let pet: Pet

    @Environment(\.dismiss) private var dismiss
    @State private var weightString: String = ""
    @State private var date: Date = Date()
    @State private var notes: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Kilo") {
                    HStack {
                        TextField("0,0", text: $weightString)
                            .keyboardType(.decimalPad)
                            .font(.title2.weight(.semibold))
                        Text("kg")
                            .foregroundStyle(.secondary)
                    }
                }

                Section("Tarih") {
                    DatePicker("Tarih", selection: $date, displayedComponents: .date)
                }

                Section("Notlar") {
                    TextField("İsteğe bağlı notlar", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Kilo Kaydet")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        save()
                    }
                    .disabled(Double(weightString.replacingOccurrences(of: ",", with: ".")) == nil || Double(weightString.replacingOccurrences(of: ",", with: "."))! <= 0)
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
    }

    private func save() {
        guard let weight = Double(weightString.replacingOccurrences(of: ",", with: ".")), weight > 0 else { return }
        store.addWeightLog(to: pet, weightKg: weight, date: date, notes: notes)
        dismiss()
    }
}
