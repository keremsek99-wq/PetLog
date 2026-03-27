import SwiftUI
import SwiftData
import PhotosUI

struct MilestoneTimelineView: View {
    let store: PetStore
    let premiumManager: PremiumManager

    @State private var showAddMilestone = false

    private var pet: Pet? { store.selectedPet }

    private var sortedMilestones: [Milestone] {
        (pet?.milestones ?? []).sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            Group {
                if sortedMilestones.isEmpty {
                    ContentUnavailableView {
                        Label("Henüz Anı Yok", systemImage: "star.circle")
                    } description: {
                        Text("İlk yürüyüş, ilk banyo gibi özel anları kaydedin.")
                    } actions: {
                        Button("Anı Ekle") { showAddMilestone = true }
                            .buttonStyle(.borderedProminent)
                    }
                } else {
                    timelineList
                }
            }
            .navigationTitle("Anılar & Miladlar")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddMilestone = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddMilestone) {
                AddMilestoneSheet(store: store)
            }
        }
    }

    // MARK: - Timeline List

    private var timelineList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(sortedMilestones.enumerated()), id: \.element.id) { index, milestone in
                    HStack(alignment: .top, spacing: 16) {
                        // Timeline line + dot
                        VStack(spacing: 0) {
                            if index > 0 {
                                Rectangle()
                                    .fill(Color(.tertiaryLabel))
                                    .frame(width: 2, height: 20)
                            } else {
                                Spacer().frame(height: 20)
                            }

                            ZStack {
                                Circle()
                                    .fill(categoryColor(milestone.category))
                                    .frame(width: 36, height: 36)
                                Text(milestone.emoji)
                                    .font(.body)
                            }

                            if index < sortedMilestones.count - 1 {
                                Rectangle()
                                    .fill(Color(.tertiaryLabel))
                                    .frame(width: 2)
                                    .frame(maxHeight: .infinity)
                            }
                        }
                        .frame(width: 36)

                        // Content card
                        VStack(alignment: .leading, spacing: 6) {
                            Text(milestone.title)
                                .font(.headline)

                            Text(milestone.date, style: .date)
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            // Days ago
                            let daysAgo = Calendar.current.dateComponents([.day], from: milestone.date, to: Date()).day ?? 0
                            if daysAgo > 0 {
                                Text("\(daysAgo) gün önce")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                            } else {
                                Text("Bugün!")
                                    .font(.caption2)
                                    .foregroundStyle(.green)
                            }

                            if !milestone.notes.isEmpty {
                                Text(milestone.notes)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(3)
                            }

                            if let photoData = milestone.photoData, let uiImage = UIImage(data: photoData) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 120)
                                    .clipShape(.rect(cornerRadius: 10))
                            }

                            HStack {
                                Text(milestone.category.rawValue)
                                    .font(.caption2)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(categoryColor(milestone.category).opacity(0.15))
                                    .foregroundStyle(categoryColor(milestone.category))
                                    .clipShape(Capsule())
                                Spacer()
                            }
                        }
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))
                        .padding(.bottom, 8)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
    }

    private func categoryColor(_ category: MilestoneCategory) -> Color {
        switch category {
        case .firstDay: return .blue
        case .health: return .red
        case .training: return .orange
        case .social: return .pink
        case .growth: return .green
        case .birthday: return .purple
        case .travel: return .teal
        case .custom: return .yellow
        }
    }
}

// MARK: - Add Milestone Sheet

struct AddMilestoneSheet: View {
    let store: PetStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var category: MilestoneCategory = .custom
    @State private var emoji = ""
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var photoData: Data? = nil

    private let presets: [(String, String, MilestoneCategory)] = [
        ("🏠 Eve Geliş", "İlk gün eve geldi", .firstDay),
        ("🐾 İlk Yürüyüş", "İlk kez dışarı çıktı", .firstDay),
        ("🛁 İlk Banyo", "İlk kez yıkandı", .firstDay),
        ("🎓 İlk Komut", "İlk komutu öğrendi", .training),
        ("💉 İlk Aşı", "İlk aşısını oldu", .health),
        ("🐕 İlk Park", "İlk kez parka gitti", .social),
        ("✂️ İlk Tıraş", "İlk kez traş oldu", .firstDay),
        ("🎂 Doğum Günü", "Doğum günü kutlandı", .birthday),
    ]

    var body: some View {
        NavigationStack {
            Form {
                // Header
                Section {
                    HStack {
                        Text("⭐")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("Yeni Anı")
                                .font(.headline)
                            Text("Özel bir anı kaydedin")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                // Presets
                Section("Hazır Şablonlar") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(presets, id: \.0) { preset in
                                Button {
                                    title = preset.0
                                    notes = preset.1
                                    category = preset.2
                                    emoji = String(preset.0.prefix(2)).trimmingCharacters(in: .whitespaces)
                                } label: {
                                    Text(preset.0)
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(title == preset.0 ? Color.accentColor : Color(.tertiarySystemGroupedBackground))
                                        .foregroundStyle(title == preset.0 ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                }

                Section("Detaylar") {
                    TextField("Anı Başlığı", text: $title)

                    Picker("Kategori", selection: $category) {
                        ForEach(MilestoneCategory.allCases, id: \.self) { cat in
                            Text("\(cat.defaultEmoji) \(cat.rawValue)").tag(cat)
                        }
                    }

                    DatePicker("Tarih", selection: $date, displayedComponents: .date)

                    TextField("Notlar", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Fotoğraf") {
                    if let data = photoData, let uiImage = UIImage(data: data) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                            .clipShape(.rect(cornerRadius: 12))
                    }

                    PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                        Label(photoData == nil ? "Fotoğraf Ekle" : "Fotoğrafı Değiştir", systemImage: "camera.fill")
                    }
                    .onChange(of: selectedPhotoItem) { _, newItem in
                        Task {
                            if let data = try? await newItem?.loadTransferable(type: Data.self) {
                                photoData = UIImage(data: data)?.jpegData(compressionQuality: 0.6)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Anı Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveMilestone()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

    private func saveMilestone() {
        guard let pet = store.selectedPet else { return }
        let milestoneEmoji = emoji.isEmpty ? category.defaultEmoji : emoji
        let milestone = Milestone(title: title, emoji: milestoneEmoji, date: date, notes: notes, category: category)
        milestone.photoData = photoData
        milestone.pet = pet
        store.modelContext.insert(milestone)
    }
}
