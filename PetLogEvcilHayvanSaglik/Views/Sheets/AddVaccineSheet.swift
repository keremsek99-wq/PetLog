import SwiftUI

struct AddVaccineSheet: View {
    let store: PetStore
    let pet: Pet

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var dateAdministered: Date = Date()
    @State private var hasDueDate: Bool = false
    @State private var dueDate: Date = Calendar.current.date(byAdding: .year, value: 1, to: Date()) ?? Date()
    @State private var veterinarian: String = ""
    @State private var notes: String = ""
    @State private var saved = false

    private let commonVaccines = ["Kuduz", "Karma (DHPPi)", "Lösemi (FeLV)", "İç Parazit", "Dış Parazit", "Leptospiroz", "Bordetella"]

    var body: some View {
        NavigationStack {
            Form {
                Section("Aşı") {
                    TextField("Aşı Adı", text: $name)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(commonVaccines, id: \.self) { v in
                                Button {
                                    name = v
                                } label: {
                                    Text(v)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(name == v ? Color.purple : Color(.tertiarySystemGroupedBackground))
                                        .foregroundStyle(name == v ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    DatePicker("Yapıldığı Tarih", selection: $dateAdministered, displayedComponents: .date)
                }

                Section("Sonraki Tarih") {
                    Toggle("Hatırlatma Tarihi Belirle", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Sonraki Tarih", selection: $dueDate, in: dateAdministered..., displayedComponents: .date)
                    }
                }

                Section("Detaylar") {
                    TextField("Veteriner", text: $veterinarian)
                    TextField("Notlar", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Aşı Ekle")
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
        store.addVaccine(to: pet, name: name, dateAdministered: dateAdministered, dueDate: hasDueDate ? dueDate : nil, vet: veterinarian, notes: notes)
        saved = true
        dismiss()
    }
}
