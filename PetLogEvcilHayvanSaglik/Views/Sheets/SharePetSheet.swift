import SwiftUI

struct PetShareCardView: View {
    let pet: Pet
    let store: PetStore

    var body: some View {
        VStack(spacing: 0) {
            // Header gradient
            ZStack(alignment: .bottomLeading) {
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .frame(height: 140)

                HStack(spacing: 14) {
                    if let photoData = pet.photoData, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 64, height: 64)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 3))
                    } else {
                        Image(systemName: pet.species.icon)
                            .font(.title)
                            .foregroundStyle(.white)
                            .frame(width: 64, height: 64)
                            .background(.white.opacity(0.2))
                            .clipShape(Circle())
                            .overlay(Circle().stroke(.white, lineWidth: 3))
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(pet.name)
                            .font(.title2.weight(.bold))
                            .foregroundStyle(.white)
                        Text("\(pet.species.rawValue) · \(pet.breed.isEmpty ? "Karışık" : pet.breed)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }
                .padding()
            }

            // Stats
            VStack(spacing: 16) {
                HStack(spacing: 20) {
                    statItem(value: pet.age, label: "Yaş", icon: "birthday.cake.fill")
                    statItem(value: pet.latestWeight != nil ? String(format: "%.1f kg", pet.latestWeight!) : "—", label: "Kilo", icon: "scalemass.fill")
                    statItem(value: "\(pet.vaccineRecords.count)", label: "Aşı", icon: "syringe.fill")
                    statItem(value: "\(pet.vetVisits.count)", label: "Vet Ziyaret", icon: "cross.case.fill")
                }

                Divider()

                HStack(spacing: 20) {
                    miniStat(title: "Aktif İlaç", value: "\(pet.activeMedications.count)")
                    miniStat(title: "Bu Ay", value: store.monthlySpending(for: pet).formatted(.currency(code: "TRY")))
                    miniStat(title: "Fotoğraf", value: "\(pet.photoLogs.count)")
                }

                HStack {
                    Image(systemName: "pawprint.fill")
                        .foregroundStyle(.blue.opacity(0.3))
                    Text("PetLog")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(Date().formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding()
            .background(Color(.systemBackground))
        }
        .clipShape(.rect(cornerRadius: 16))
        .shadow(color: .black.opacity(0.1), radius: 10, y: 4)
    }

    private func statItem(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundStyle(.blue)
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private func miniStat(title: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.caption, design: .rounded, weight: .bold))
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SharePetSheet: View {
    let pet: Pet
    let store: PetStore
    @Environment(\.dismiss) private var dismiss

    @MainActor
    private func renderShareImage() -> UIImage? {
        let renderer = ImageRenderer(content:
            PetShareCardView(pet: pet, store: store)
                .frame(width: 360)
        )
        renderer.scale = 3
        return renderer.uiImage
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                PetShareCardView(pet: pet, store: store)
                    .padding(.horizontal)

                if let image = renderShareImage() {
                    ShareLink(item: Image(uiImage: image), preview: SharePreview("\(pet.name) - PetLog", image: Image(uiImage: image))) {
                        Label("Paylaş", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.blue)
                            .foregroundStyle(.white)
                            .clipShape(.rect(cornerRadius: 12))
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.top)
            .navigationTitle("Pet Kartı Paylaş")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Kapat") { dismiss() }
                }
            }
        }
    }
}
