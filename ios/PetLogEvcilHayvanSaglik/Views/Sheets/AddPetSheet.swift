import SwiftUI
import PhotosUI

struct AddPetSheet: View {
    let store: PetStore
    var editingPet: Pet? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var species: PetSpecies = .unspecified
    @State private var breed: String = ""
    @State private var birthdate: Date = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
    @State private var sex: PetSex = .unknown
    @State private var isNeutered: Bool = false
    @State private var weightTargetKg: String = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil
    @State private var showDeleteAlert = false

    private var isEditing: Bool { editingPet != nil }

    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Avatar Section
                Section {
                    HStack {
                        Spacer()
                        VStack(spacing: 12) {
                            PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                                petAvatarView
                            }
                            .onChange(of: selectedPhotoItem) { _, newValue in
                                loadPhoto(from: newValue)
                            }

                            Text(isEditing ? name : (name.isEmpty ? "Yeni Hayvan" : name))
                                .font(.title3.weight(.semibold))

                            if photoData == nil {
                                Text("Fotoğraf eklemek için dokunun")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                    }
                    .listRowBackground(Color.clear)
                }

                // MARK: - Basic Info
                Section("Temel Bilgiler") {
                    TextField("İsim", text: $name)
                        .font(.body.weight(.medium))

                    Picker("Tür", selection: $species) {
                        ForEach(PetSpecies.allCases, id: \.self) { s in
                            Label(s.rawValue, systemImage: s.icon).tag(s)
                        }
                    }
                    .onChange(of: species) { _, _ in
                        // Reset breed when species changes
                        breed = ""
                    }

                    breedPicker
                }

                // MARK: - Details
                Section("Detaylar") {
                    DatePicker("Doğum Tarihi", selection: $birthdate, in: ...Date(), displayedComponents: .date)

                    Picker("Cinsiyet", selection: $sex) {
                        ForEach(PetSex.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }

                    Toggle("Kısırlaştırılmış", isOn: $isNeutered)

                    HStack {
                        Text("Hedef Kilo")
                        Spacer()
                        TextField("kg", text: $weightTargetKg)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 80)
                    }
                }

                // MARK: - Delete (Edit Mode)
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showDeleteAlert = true
                        } label: {
                            HStack {
                                Spacer()
                                Label("Hayvanı Sil", systemImage: "trash")
                                    .foregroundStyle(.red)
                                Spacer()
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Düzenle" : "Hayvan Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Kaydet" : "Ekle") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .alert("Hayvanı Sil", isPresented: $showDeleteAlert) {
                Button("İptal", role: .cancel) {}
                Button("Sil", role: .destructive) {
                    if let pet = editingPet {
                        store.deletePet(pet)
                    }
                    dismiss()
                }
            } message: {
                Text("\(editingPet?.name ?? "") ve tüm ilişkili veriler kalıcı olarak silinecektir.")
            }
            .onAppear {
                if let pet = editingPet {
                    name = pet.name
                    species = pet.species
                    breed = pet.breed
                    birthdate = pet.birthdate
                    sex = pet.sex
                    isNeutered = pet.isNeutered
                    photoData = pet.photoData
                    if let target = pet.weightTargetKg {
                        weightTargetKg = String(format: "%.1f", target)
                    }
                }
            }
        }
    }

    // MARK: - Breed Picker

    @ViewBuilder
    private var breedPicker: some View {
        let knownBreeds = BreedDatabase.breeds(for: species)
        if knownBreeds.isEmpty {
            TextField("Irk (isteğe bağlı)", text: $breed)
        } else {
            Picker("Irk", selection: $breed) {
                Text("Seçiniz").tag("")
                ForEach(knownBreeds, id: \.name) { breedInfo in
                    Text(breedInfo.name).tag(breedInfo.name)
                }
                Text("Diğer").tag("__other__")
            }
            if breed == "__other__" {
                TextField("Irk adı girin", text: $customBreed)
            }
        }
    }

    @State private var customBreed: String = ""

    // MARK: - Pet Avatar

    private var petAvatarView: some View {
        Group {
            if let photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 88, height: 88)
                    .clipShape(Circle())
                    .overlay(
                        Circle()
                            .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    )
                    .overlay(alignment: .bottomTrailing) {
                        Image(systemName: "camera.circle.fill")
                            .font(.title3)
                            .foregroundStyle(.blue)
                            .background(Circle().fill(.white).padding(2))
                    }
            } else {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: species.icon)
                        .font(.system(size: 40))
                        .foregroundStyle(.blue)
                }
                .overlay(alignment: .bottomTrailing) {
                    Image(systemName: "camera.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.blue)
                        .background(Circle().fill(.white).padding(2))
                }
            }
        }
    }

    // MARK: - Photo Loading

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                // Compress to max 500KB for storage efficiency
                if let uiImage = UIImage(data: data),
                   let compressed = uiImage.jpegData(compressionQuality: 0.5) {
                    await MainActor.run {
                        photoData = compressed
                    }
                }
            }
        }
    }

    // MARK: - Save

    private func save() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let targetWeight = Double(weightTargetKg.replacingOccurrences(of: ",", with: "."))
        let resolvedBreed = (breed == "__other__") ? customBreed.trimmingCharacters(in: .whitespaces) : breed

        if let pet = editingPet {
            // Edit existing
            store.updatePet(pet, name: trimmedName, species: species, breed: resolvedBreed, birthdate: birthdate, sex: sex, isNeutered: isNeutered, weightTargetKg: targetWeight, photoData: photoData)
        } else {
            // Create new
            let pet = Pet(name: trimmedName, species: species, breed: resolvedBreed, birthdate: birthdate, sex: sex, isNeutered: isNeutered, weightTargetKg: targetWeight)
            pet.photoData = photoData
            store.addPet(pet)
        }
        dismiss()
    }
}
