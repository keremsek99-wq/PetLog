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
    @State private var isCompareMode = false
    @State private var comparePhoto1: PhotoLog? = nil
    @State private var comparePhoto2: PhotoLog? = nil
    @State private var selectedDetailPhoto: PhotoLog? = nil

    private var pet: Pet? { store.selectedPet }

    private var sortedPhotos: [PhotoLog] {
        (pet?.photoLogs ?? []).sorted { $0.date > $1.date }
    }

    private var groupedByMonth: [(String, [PhotoLog])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "tr_TR")
        formatter.dateFormat = "MMMM yyyy"

        let grouped = Dictionary(grouping: sortedPhotos) { formatter.string(from: $0.date) }
        return grouped.sorted { lhs, rhs in
            guard let l = lhs.value.first?.date, let r = rhs.value.first?.date else { return false }
            return l > r
        }
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
                } else if isCompareMode {
                    compareView
                } else {
                    photoGrid
                }
            }
            .navigationTitle("Fotoğraf Albümü")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if sortedPhotos.count >= 2 {
                        Button {
                            withAnimation(.spring(duration: 0.3)) {
                                isCompareMode.toggle()
                                if !isCompareMode {
                                    comparePhoto1 = nil
                                    comparePhoto2 = nil
                                }
                            }
                        } label: {
                            Label(isCompareMode ? "Grid" : "Karşılaştır", systemImage: isCompareMode ? "square.grid.3x3" : "rectangle.split.2x1")
                        }
                    }
                }
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
            .sheet(item: $selectedDetailPhoto) { photo in
                photoDetailView(photo)
            }
        }
    }

    // MARK: - Photo Grid (grouped by month)

    private var photoGrid: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 16) {
                // Stats header
                if sortedPhotos.count >= 2, let first = sortedPhotos.last, let last = sortedPhotos.first {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("📸 \(sortedPhotos.count) fotoğraf")
                                .font(.subheadline.weight(.semibold))
                            let days = Calendar.current.dateComponents([.day], from: first.date, to: last.date).day ?? 0
                            Text("\(days) günlük büyüme yolculuğu")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                }

                ForEach(groupedByMonth, id: \.0) { month, photos in
                    Section {
                        LazyVGrid(columns: columns, spacing: 2) {
                            ForEach(photos, id: \.id) { photo in
                                photoCell(photo)
                            }
                        }
                    } header: {
                        Text(month)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 24)
        }
    }

    private func photoCell(_ photo: PhotoLog) -> some View {
        Group {
            if let uiImage = UIImage(data: photo.imageData) {
                Button {
                    selectedDetailPhoto = photo
                } label: {
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
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Photo Detail View

    private func photoDetailView(_ photo: PhotoLog) -> some View {
        NavigationStack {
            VStack(spacing: 16) {
                if let uiImage = UIImage(data: photo.imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFit()
                        .clipShape(.rect(cornerRadius: 16))
                        .shadow(radius: 8)
                }

                VStack(spacing: 4) {
                    Text(photo.date, style: .date)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if !photo.caption.isEmpty {
                        Text(photo.caption)
                            .font(.body)
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Fotoğraf Detayı")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") { selectedDetailPhoto = nil }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Compare View (Before / After)

    private var compareView: some View {
        VStack(spacing: 16) {
            Text("İki fotoğraf seçin")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            // Selected photos display
            HStack(spacing: 12) {
                compareSlot(photo: comparePhoto1, label: "Önce")
                compareSlot(photo: comparePhoto2, label: "Sonra")
            }
            .padding(.horizontal)

            // Compare result
            if let p1 = comparePhoto1, let p2 = comparePhoto2 {
                let days = abs(Calendar.current.dateComponents([.day], from: p1.date, to: p2.date).day ?? 0)
                HStack {
                    Image(systemName: "arrow.left.and.right")
                        .foregroundStyle(.secondary)
                    Text("\(days) gün fark")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .padding(8)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(Capsule())
            }

            Divider()

            // Photo selection grid
            ScrollView {
                LazyVGrid(columns: columns, spacing: 2) {
                    ForEach(sortedPhotos, id: \.id) { photo in
                        if let uiImage = UIImage(data: photo.imageData) {
                            Button {
                                selectForCompare(photo)
                            } label: {
                                ZStack(alignment: .topTrailing) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(minHeight: 100)
                                        .clipped()

                                    if comparePhoto1?.id == photo.id {
                                        selectionBadge("1")
                                    } else if comparePhoto2?.id == photo.id {
                                        selectionBadge("2")
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }

    private func compareSlot(photo: PhotoLog?, label: String) -> some View {
        VStack(spacing: 4) {
            if let photo, let uiImage = UIImage(data: photo.imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(height: 180)
                    .clipped()
                    .clipShape(.rect(cornerRadius: 12))

                Text(photo.date, style: .date)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.tertiarySystemGroupedBackground))
                    .frame(height: 180)
                    .overlay {
                        VStack(spacing: 4) {
                            Image(systemName: "photo")
                                .font(.title2)
                                .foregroundStyle(.tertiary)
                            Text(label)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func selectionBadge(_ number: String) -> some View {
        Text(number)
            .font(.caption2.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 22, height: 22)
            .background(Circle().fill(.blue))
            .padding(4)
    }

    private func selectForCompare(_ photo: PhotoLog) {
        withAnimation(.spring(duration: 0.2)) {
            if comparePhoto1?.id == photo.id {
                comparePhoto1 = nil
            } else if comparePhoto2?.id == photo.id {
                comparePhoto2 = nil
            } else if comparePhoto1 == nil {
                comparePhoto1 = photo
            } else if comparePhoto2 == nil {
                comparePhoto2 = photo
            } else {
                comparePhoto2 = photo
            }
        }
    }

    // MARK: - Add Photo Sheet

    private var addPhotoSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    if let data = selectedImage, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .clipShape(.rect(cornerRadius: 16))
                            .shadow(radius: 4)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Açıklama")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.leading, 4)

                        TextField("Bu anı tanımlayın...", text: $caption)
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))
                    }
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
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
                    .fontWeight(.semibold)
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
