import SwiftUI

struct DocumentListView: View {
    let pet: Pet
    let store: PetStore
    let premiumManager: PremiumManager
    @State private var showAddDocument = false
    @State private var selectedDocument: PetDocument?

    private var sortedDocuments: [PetDocument] {
        pet.documents.sorted { $0.date > $1.date }
    }

    var body: some View {
        List {
            if sortedDocuments.isEmpty {
                Section {
                    ContentUnavailableView {
                        Label("Belge Yok", systemImage: "doc.text.fill")
                    } description: {
                        Text("Aşı kartı, sigorta, veteriner raporu gibi belgeleri buradan yönetin.")
                    } actions: {
                        Button("Belge Ekle") { showAddDocument = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                let grouped = Dictionary(grouping: sortedDocuments) { $0.documentType }
                let sortedKeys = grouped.keys.sorted { $0.rawValue < $1.rawValue }

                ForEach(sortedKeys, id: \.self) { type in
                    Section(type.rawValue) {
                        ForEach(grouped[type] ?? [], id: \.id) { doc in
                            Button {
                                selectedDocument = doc
                            } label: {
                                documentRow(doc)
                            }
                            .buttonStyle(.plain)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    store.deleteDocument(doc)
                                } label: {
                                    Label("Sil", systemImage: "trash")
                                }
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Belgelerim")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showAddDocument = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .symbolRenderingMode(.hierarchical)
                }
            }
        }
        .sheet(isPresented: $showAddDocument) {
            AddDocumentSheet(store: store, premiumManager: premiumManager)
        }
        .sheet(item: $selectedDocument) { doc in
            DocumentDetailView(document: doc)
        }
    }

    private func documentRow(_ doc: PetDocument) -> some View {
        HStack(spacing: 12) {
            if let imageData = doc.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 44, height: 44)
                    .clipShape(.rect(cornerRadius: 8))
            } else {
                Image(systemName: doc.documentType.icon)
                    .font(.title3)
                    .foregroundStyle(.teal)
                    .frame(width: 44, height: 44)
                    .background(Color.teal.opacity(0.12))
                    .clipShape(.rect(cornerRadius: 8))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(doc.title)
                    .font(.subheadline.weight(.medium))
                HStack(spacing: 4) {
                    Text(doc.date.formatted(date: .abbreviated, time: .omitted))
                    if !doc.notes.isEmpty {
                        Text("·")
                        Text(doc.notes)
                            .lineLimit(1)
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if doc.imageData != nil {
                Image(systemName: "photo.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct DocumentDetailView: View {
    let document: PetDocument

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    if let imageData = document.imageData, let uiImage = UIImage(data: imageData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(.rect(cornerRadius: 12))
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: document.documentType.icon)
                                .font(.title3)
                                .foregroundStyle(.teal)
                            Text(document.documentType.rawValue)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        Text(document.title)
                            .font(.title2.weight(.bold))

                        HStack(spacing: 6) {
                            Image(systemName: "calendar")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(document.date.formatted(date: .long, time: .omitted))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }

                        if !document.notes.isEmpty {
                            Text(document.notes)
                                .font(.body)
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding()
            }
            .navigationTitle("Belge Detayı")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
