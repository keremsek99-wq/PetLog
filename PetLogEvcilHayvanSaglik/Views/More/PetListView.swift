import SwiftUI

struct PetListView: View {
    let store: PetStore
    let premiumManager: PremiumManager
    @State private var showAddPet = false
    @State private var showPaywall = false
    @State private var editingPet: Pet? = nil

    var body: some View {
        List {
            ForEach(store.allPets(), id: \.id) { pet in
                HStack(spacing: 12) {
                    petAvatar(pet)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(pet.name)
                            .font(.headline)
                        Text("\(pet.species.rawValue) · \(pet.breed.isEmpty ? "Irk belirtilmemiş" : pet.breed) · \(pet.age)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    if store.selectedPet?.id == pet.id {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.blue)
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    store.selectedPet = pet
                }
                .swipeActions(edge: .trailing) {
                    Button(role: .destructive) {
                        store.deletePet(pet)
                    } label: {
                        Label("Sil", systemImage: "trash")
                    }
                    Button {
                        editingPet = pet
                    } label: {
                        Label("Düzenle", systemImage: "pencil")
                    }
                    .tint(.blue)
                }
            }
        }
        .navigationTitle("Hayvanlarım")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if store.canAddMorePets(isPremium: premiumManager.hasFullAccess) {
                        showAddPet = true
                    } else {
                        showPaywall = true
                    }
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $showAddPet) {
            AddPetSheet(store: store)
        }
        .sheet(item: $editingPet) { pet in
            AddPetSheet(store: store, editingPet: pet)
        }
        .sheet(isPresented: $showPaywall) {
            PetLogPaywallView(premiumManager: premiumManager)
        }
    }

    private func petAvatar(_ pet: Pet) -> some View {
        Group {
            if let photoData = pet.photoData, let uiImage = UIImage(data: photoData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 36, height: 36)
                    .clipShape(Circle())
            } else {
                Image(systemName: pet.species.icon)
                    .font(.title3)
                    .foregroundStyle(.blue)
                    .frame(width: 36, height: 36)
                    .background(Color.blue.opacity(0.12))
                    .clipShape(Circle())
            }
        }
    }
}
