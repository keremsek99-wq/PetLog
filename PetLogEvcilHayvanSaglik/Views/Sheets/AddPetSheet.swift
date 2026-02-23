import SwiftUI

struct AddPetSheet: View {
    let store: PetStore

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var species: PetSpecies = .dog
    @State private var breed: String = ""
    @State private var birthdate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var sex: PetSex = .unknown
    @State private var isNeutered: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            Image(systemName: species.icon)
                                .font(.system(size: 48))
                                .foregroundStyle(.blue)
                                .frame(width: 80, height: 80)
                                .background(Color.blue.opacity(0.12))
                                .clipShape(Circle())
                            Text(name.isEmpty ? "Yeni Hayvan" : name)
                                .font(.title3.weight(.semibold))
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Temel Bilgiler") {
                    TextField("İsim", text: $name)
                        .font(.body.weight(.medium))

                    Picker("Tür", selection: $species) {
                        ForEach(PetSpecies.allCases, id: \.self) { s in
                            Label(s.rawValue, systemImage: s.icon).tag(s)
                        }
                    }

                    TextField("Irk (isteğe bağlı)", text: $breed)
                }

                Section("Detaylar") {
                    DatePicker("Doğum Tarihi", selection: $birthdate, in: ...Date(), displayedComponents: .date)

                    Picker("Cinsiyet", selection: $sex) {
                        ForEach(PetSex.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }

                    Toggle("Kısırlaştırılmış", isOn: $isNeutered)
                }
            }
            .navigationTitle("Hayvan Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Ekle") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func save() {
        let pet = Pet(name: name.trimmingCharacters(in: .whitespaces), species: species, breed: breed, birthdate: birthdate, sex: sex, isNeutered: isNeutered)
        store.addPet(pet)
        dismiss()
    }
}
