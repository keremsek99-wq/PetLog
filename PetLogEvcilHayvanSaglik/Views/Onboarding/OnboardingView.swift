import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    let store: PetStore

    @State private var currentPage = 0
    @State private var showAddPet = false

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $currentPage) {
                onboardingPage(
                    icon: "pawprint.fill",
                    iconColor: .blue,
                    title: "PetLog'a Hoş Geldiniz",
                    subtitle: "Evcil hayvanınızın kişisel sağlık asistanı ve finansal takipçisi — hepsi tek bir yerde."
                )
                .tag(0)

                onboardingPage(
                    icon: "heart.text.clipboard.fill",
                    iconColor: .green,
                    title: "Sağlığı Takip Edin",
                    subtitle: "Kilo, aşılar, ilaçlar ve veteriner ziyaretlerini izleyin. Hiçbir hatırlatmayı kaçırmayın."
                )
                .tag(1)

                onboardingPage(
                    icon: "chart.pie.fill",
                    iconColor: .orange,
                    title: "Harcamaları Yönetin",
                    subtitle: "Paranızın nereye gittiğini görün. Harcamaları takip edin, mama maliyetlerini planlayın."
                )
                .tag(2)

                onboardingPage(
                    icon: "brain.head.profile.fill",
                    iconColor: .purple,
                    title: "Akıllı Öneriler",
                    subtitle: "Yapay zeka destekli öneriler trendleri yakalar, anormallikleri işaret eder ve adımlar önerir."
                )
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            VStack(spacing: 12) {
                if currentPage == 3 {
                    Button {
                        showAddPet = true
                    } label: {
                        Text("Hayvanını Ekle")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .sensoryFeedback(.impact(flexibility: .solid), trigger: showAddPet)
                } else {
                    Button {
                        withAnimation(.snappy) {
                            currentPage += 1
                        }
                    } label: {
                        Text("Devam")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                }

                if currentPage < 3 {
                    Button("Atla") {
                        showAddPet = true
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: $showAddPet, onDismiss: {
            if !store.allPets().isEmpty {
                hasCompletedOnboarding = true
            }
        }) {
            OnboardingAddPetSheet(store: store) {
                hasCompletedOnboarding = true
            }
        }
    }

    private func onboardingPage(icon: String, iconColor: Color, title: String, subtitle: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: icon)
                .font(.system(size: 72))
                .foregroundStyle(iconColor)
                .symbolEffect(.bounce, value: currentPage)
            Text(title)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text(subtitle)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            Spacer()
        }
    }
}

struct OnboardingAddPetSheet: View {
    let store: PetStore
    let onComplete: () -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var species: PetSpecies = .unspecified
    @State private var breed: String = ""
    @State private var customBreed: String = ""
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
                            Text("Hayvanınızı tanıyalım!")
                                .font(.headline)
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
                    .onChange(of: species) { _, _ in
                        breed = ""
                    }

                    breedPicker
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
                    Button("Başla") {
                        let resolvedBreed = (breed == "__other__") ? customBreed.trimmingCharacters(in: .whitespaces) : breed
                        let pet = Pet(name: name.trimmingCharacters(in: .whitespaces), species: species, breed: resolvedBreed, birthdate: birthdate, sex: sex, isNeutered: isNeutered)
                        store.addPet(pet)
                        onComplete()
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
        }
    }

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
}
