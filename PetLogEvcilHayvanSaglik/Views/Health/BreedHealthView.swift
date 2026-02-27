import SwiftUI

struct BreedHealthView: View {
    let pet: Pet

    private var breedInfo: BreedInfo? {
        BreedDatabase.breedInfo(species: pet.species, breedName: pet.breed)
    }

    var body: some View {
        List {
            if let info = breedInfo {
                Section {
                    HStack(spacing: 14) {
                        Image(systemName: pet.species.icon)
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 48, height: 48)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 4) {
                            Text(info.name)
                                .font(.title3.weight(.bold))
                            HStack(spacing: 8) {
                                Label(info.size, systemImage: "ruler")
                                Text("·")
                                    .foregroundStyle(.tertiary)
                                Label(info.lifespan, systemImage: "heart.fill")
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section {
                    ForEach(info.healthRisks, id: \.self) { risk in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.orange)
                                .font(.caption)
                                .padding(.top, 2)
                            Text(risk)
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Label("Sağlık Riskleri", systemImage: "exclamationmark.shield.fill")
                }

                Section {
                    ForEach(info.recommendedChecks, id: \.self) { check in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "stethoscope")
                                .foregroundStyle(.purple)
                                .font(.caption)
                                .padding(.top, 2)
                            Text(check)
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Label("Önerilen Kontroller", systemImage: "checklist")
                }

                Section {
                    ForEach(info.careNotes, id: \.self) { note in
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: "lightbulb.fill")
                                .foregroundStyle(.yellow)
                                .font(.caption)
                                .padding(.top, 2)
                            Text(note)
                                .font(.subheadline)
                        }
                    }
                } header: {
                    Label("Bakım Notları", systemImage: "heart.text.clipboard")
                }
                // MARK: - Sources
                if !info.sources.isEmpty {
                    Section {
                        ForEach(info.sources, id: \.self) { source in
                            if let url = URL(string: source) {
                                Link(destination: url) {
                                    HStack(spacing: 10) {
                                        Image(systemName: "link")
                                            .foregroundStyle(.blue)
                                            .font(.caption)
                                        Text(url.host ?? source)
                                            .font(.subheadline)
                                            .foregroundStyle(.blue)
                                        Spacer()
                                        Image(systemName: "arrow.up.right.square")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }
                    } header: {
                        Label("Kaynaklar", systemImage: "book.closed.fill")
                    }
                }

                // MARK: - Medical Disclaimer
                Section {
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                            .font(.subheadline)
                        Text(BreedDatabase.medicalDisclaimer)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                } header: {
                    Label("Uyarı", systemImage: "info.circle")
                }
            } else {
                ContentUnavailableView {
                    Label("Irk Bilgisi Bulunamadı", systemImage: "questionmark.circle")
                } description: {
                    if pet.breed.isEmpty {
                        Text("Irk bilgisi eklendiğinde sağlık önerileri burada görünecek.")
                    } else {
                        Text("\"\(pet.breed)\" ırkı için henüz detaylı sağlık bilgisi bulunmuyor.")
                    }
                }
            }
        }
        .navigationTitle("Irk Sağlık Rehberi")
        .navigationBarTitleDisplayMode(.inline)
    }
}
