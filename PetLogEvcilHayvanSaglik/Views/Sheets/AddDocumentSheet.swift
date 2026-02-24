import SwiftUI
import SwiftData
import PhotosUI

struct AddDocumentSheet: View {
    let store: PetStore
    let premiumManager: PremiumManager
    @Environment(\.dismiss) private var dismiss
    @State private var documentType: DocumentType = .vaccineCard
    @State private var title = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var imageData: Data? = nil

    private var currentDocCount: Int {
        store.selectedPet?.documents.count ?? 0
    }

    private var canAddMore: Bool {
        premiumManager.hasFullAccess || currentDocCount < 5
    }

    var body: some View {
        NavigationStack {
            Form {
                if !canAddMore {
                    Section {
                        HStack {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(.orange)
                            Text("Ücretsiz planda en fazla 5 belge eklenebilir. Premium'a geçin.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                Section("Belge Tipi") {
                    Picker("Tip", selection: $documentType) {
                        ForEach(DocumentType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                }

                Section("Bilgiler") {
                    TextField("Belge başlığı", text: $title)
                    DatePicker("Tarih", selection: $date, displayedComponents: .date)
                }

                Section("Fotoğraf") {
                    if let data = imageData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(.rect(cornerRadius: 12))
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(imageData == nil ? "Fotoğraf Seç" : "Fotoğrafı Değiştir", systemImage: "photo.on.rectangle")
                    }
                }

                Section("Notlar") {
                    TextField("Opsiyonel not...", text: $notes, axis: .vertical)
                        .lineLimit(3)
                }
            }
            .navigationTitle("Belge Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        save()
                    }
                    .disabled(title.isEmpty || !canAddMore)
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
        }
    }

    private func save() {
        guard let pet = store.selectedPet else { return }
        let compressed = imageData.flatMap { UIImage(data: $0)?.jpegData(compressionQuality: 0.6) }
        let doc = PetDocument(documentType: documentType, title: title, imageData: compressed, notes: notes, date: date)
        doc.pet = pet
        store.modelContext.insert(doc)
        dismiss()
    }
}
