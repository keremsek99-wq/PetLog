import SwiftUI
import SwiftData
import PhotosUI

struct PhotoTimelineView: View {
    let store: PetStore
    let premiumManager: PremiumManager
    @State private var showAddPhoto = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var caption = ""
    @State private var selectedImage: Data? = nil

    private var pet: Pet? { store.selectedPet }

    private var sortedPhotos: [PhotoLog] {
        (pet?.photoLogs ?? []).sorted { $0.date > $1.date }
    }

    let columns = [
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2),
        GridItem(.flexible(), spacing: 2)
    ]

    var body: some View {
        NavigationStack {
            Group {
                if sortedPhotos.isEmpty {
                    ContentUnavailableView {
                        Label("Henüz Fotoğraf Yok", systemImage: "photo.on.rectangle.angled")
                    } description: {
                        Text("Evcil hayvanınızın büyüme albümünü oluşturmak için fotoğraf ekleyin.")
                    } actions: {
                        Button("Fotoğraf Ekle") { showAddPhoto = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(sortedPhotos, id: \.id) { photo in
                                if let uiImage = UIImage(data: photo.imageData) {
                                    ZStack(alignment: .bottomLeading) {
                                        Image(uiImage: uiImage)
                                            .resizable()
                                            .scaledToFill()
                                            .frame(minHeight: 120)
                                            .clipped()

                                        if !photo.caption.isEmpty {
                                            Text(photo.caption)
                                                .font(.caption2)
                                                .foregroundStyle(.white)
                                                .padding(4)
                                                .background(.black.opacity(0.5))
                                                .clipShape(.rect(cornerRadius: 4))
                                                .padding(4)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Fotoğraf Albümü")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .onChange(of: selectedPhotoItem) { _, newItem in
                Task {
                    if let data = try? await newItem?.loadTransferable(type: Data.self) {
                        selectedImage = data
                        showAddPhoto = true
                    }
                }
            }
            .sheet(isPresented: $showAddPhoto) {
                addPhotoSheet
            }
        }
    }

    private var addPhotoSheet: some View {
        NavigationStack {
            Form {
                if let data = selectedImage, let uiImage = UIImage(data: data) {
                    Section {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(.rect(cornerRadius: 12))
                    }
                }

                Section("Açıklama") {
                    TextField("Bu anı tanımlayın...", text: $caption)
                }
            }
            .navigationTitle("Fotoğraf Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") {
                        resetPhotoState()
                        showAddPhoto = false
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        savePhoto()
                    }
                    .disabled(selectedImage == nil)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func savePhoto() {
        guard let pet, let imageData = selectedImage else { return }
        let compressed = UIImage(data: imageData)?.jpegData(compressionQuality: 0.6) ?? imageData
        let log = PhotoLog(imageData: compressed, caption: caption)
        log.pet = pet
        store.modelContext.insert(log)
        resetPhotoState()
        showAddPhoto = false
    }

    private func resetPhotoState() {
        selectedImage = nil
        selectedPhotoItem = nil
        caption = ""
    }
}
