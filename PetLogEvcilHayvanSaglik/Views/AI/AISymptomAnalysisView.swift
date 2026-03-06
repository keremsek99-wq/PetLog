import SwiftUI
import PhotosUI

struct AISymptomAnalysisView: View {
    let pet: Pet
    let store: PetStore
    let premiumManager: PremiumManager

    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var description = ""
    @State private var isAnalyzing = false
    @State private var analysisResult: AIAnalysisResult?
    @State private var selectedBodyArea: BodyArea?
    @State private var symptomDuration: SymptomDuration = .today

    enum SymptomDuration: String, CaseIterable {
        case today = "Bugün başladı"
        case fewDays = "Birkaç gündür"
        case oneWeek = "1 haftadır"
        case twoWeeks = "2 haftadır"
        case month = "1 aydan fazla"
    }

    enum BodyArea: String, CaseIterable {
        case head = "Baş / Yüz"
        case ears = "Kulaklar"
        case eyes = "Gözler"
        case mouth = "Ağız / Dişler"
        case neck = "Boyun"
        case chest = "Göğüs"
        case belly = "Karın"
        case back = "Sırt"
        case legs = "Bacaklar"
        case paws = "Patiler"
        case tail = "Kuyruk"
        case skin = "Deri / Tüy (Genel)"

        var emoji: String {
            switch self {
            case .head: return "🧠"
            case .ears: return "👂"
            case .eyes: return "👁"
            case .mouth: return "🦷"
            case .neck: return "🦒"
            case .chest: return "🫁"
            case .belly: return "🤰"
            case .back: return "🔙"
            case .legs: return "🦿"
            case .paws: return "🐾"
            case .tail: return "🦯"
            case .skin: return "🧴"
            }
        }
    }

    var body: some View {
        NavigationStack {
            if let result = analysisResult {
                resultView(result)
            } else {
                inputView
            }
        }
    }

    // MARK: - Input View

    private var inputView: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                VStack(spacing: 8) {
                    Text("🤖")
                        .font(.system(size: 48))
                    Text("AI Semptom Analizi")
                        .font(.title2.weight(.bold))
                    Text("Fotoğraf ve açıklama ile ön değerlendirme alın")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("⚠️ Profesyonel veteriner tanısı yerine geçmez")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
                .padding(.top, 8)

                // Photo upload
                VStack(alignment: .leading, spacing: 8) {
                    Text("📸 Fotoğraf (opsiyonel)")
                        .font(.subheadline.weight(.semibold))

                    if let imageData = selectedImageData, let uiImage = UIImage(data: imageData) {
                        ZStack(alignment: .topTrailing) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 200)
                                .clipShape(.rect(cornerRadius: 14))

                            Button {
                                selectedImageData = nil
                                selectedPhotoItem = nil
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundStyle(.white)
                                    .shadow(radius: 4)
                            }
                            .padding(8)
                        }
                    } else {
                        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                            VStack(spacing: 8) {
                                Image(systemName: "camera.fill")
                                    .font(.title2)
                                Text("Etkilenen bölgenin fotoğrafını ekleyin")
                                    .font(.caption)
                            }
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 120)
                            .background(Color(.tertiarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 14))
                        }
                    }
                }
                .padding(.horizontal)
                .onChange(of: selectedPhotoItem) { _, newItem in
                    Task {
                        if let data = try? await newItem?.loadTransferable(type: Data.self) {
                            selectedImageData = data
                        }
                    }
                }

                // Body area selector
                VStack(alignment: .leading, spacing: 8) {
                    Text("📍 Etkilenen Bölge")
                        .font(.subheadline.weight(.semibold))

                    LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                        ForEach(BodyArea.allCases, id: \.self) { area in
                            Button {
                                selectedBodyArea = area
                            } label: {
                                VStack(spacing: 4) {
                                    Text(area.emoji)
                                        .font(.title3)
                                    Text(area.rawValue)
                                        .font(.system(size: 9))
                                        .lineLimit(1)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 10)
                                .background(selectedBodyArea == area ? Color.blue.opacity(0.15) : Color(.tertiarySystemGroupedBackground))
                                .foregroundStyle(selectedBodyArea == area ? .blue : .primary)
                                .clipShape(.rect(cornerRadius: 10))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedBodyArea == area ? Color.blue : .clear, lineWidth: 1.5)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal)

                // Duration
                VStack(alignment: .leading, spacing: 8) {
                    Text("⏱ Ne Zamandır?")
                        .font(.subheadline.weight(.semibold))

                    Picker("Süre", selection: $symptomDuration) {
                        ForEach(SymptomDuration.allCases, id: \.self) { dur in
                            Text(dur.rawValue).tag(dur)
                        }
                    }
                    .pickerStyle(.segmented)
                }
                .padding(.horizontal)

                // Description
                VStack(alignment: .leading, spacing: 8) {
                    Text("📝 Belirtileri Açıklayın")
                        .font(.subheadline.weight(.semibold))

                    TextField("Örn: Sağ ön patisini yere basmaktan kaçınıyor, hafif şişlik var...", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                        .padding(12)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 12))
                }
                .padding(.horizontal)

                // Analyze button
                Button {
                    performAnalysis()
                } label: {
                    HStack {
                        if isAnalyzing {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: "sparkles")
                        }
                        Text(isAnalyzing ? "Analiz Ediliyor..." : "AI ile Analiz Et")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
                .disabled(description.isEmpty || isAnalyzing)
                .padding(.horizontal)
            }
            .padding(.bottom, 32)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("AI Analiz")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Result View

    private func resultView(_ result: AIAnalysisResult) -> some View {
        ScrollView {
            VStack(spacing: 16) {
                // Urgency banner
                HStack(spacing: 12) {
                    Image(systemName: result.urgency.icon)
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(result.urgency.title)
                            .font(.headline)
                        Text(result.urgency.description)
                            .font(.caption)
                    }
                    Spacer()
                }
                .padding()
                .foregroundStyle(.white)
                .background(result.urgency.color)
                .clipShape(.rect(cornerRadius: 14))

                // Disclaimer
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundStyle(.orange)
                    Text("Bu bir AI ön değerlendirmesidir. Kesin tanı için mutlaka veterinere başvurun.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(Color.orange.opacity(0.1))
                .clipShape(.rect(cornerRadius: 10))

                // Analysis summary
                VStack(alignment: .leading, spacing: 10) {
                    Text("🔬 Analiz Sonucu")
                        .font(.subheadline.weight(.semibold))

                    Text(result.summary)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))

                // Possible conditions
                if !result.possibleConditions.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("📋 Olası Durumlar")
                            .font(.subheadline.weight(.semibold))

                        ForEach(result.possibleConditions, id: \.name) { condition in
                            HStack(alignment: .top, spacing: 10) {
                                Text(condition.emoji)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 3) {
                                    HStack {
                                        Text(condition.name)
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text(condition.likelihood)
                                            .font(.caption2.weight(.semibold))
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(likelihoodColor(condition.likelihood).opacity(0.12))
                                            .foregroundStyle(likelihoodColor(condition.likelihood))
                                            .clipShape(Capsule())
                                    }
                                    Text(condition.explanation)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if condition.name != result.possibleConditions.last?.name {
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 12))
                }

                // Immediate actions
                if !result.immediateActions.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("⚡ Hemen Yapılması Gerekenler")
                            .font(.subheadline.weight(.semibold))

                        ForEach(result.immediateActions, id: \.self) { action in
                            HStack(alignment: .top, spacing: 8) {
                                Image(systemName: "checkmark.circle")
                                    .foregroundStyle(.green)
                                    .font(.caption)
                                Text(action)
                                    .font(.caption)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 12))
                }

                // When to see vet
                VStack(alignment: .leading, spacing: 8) {
                    Text("🏥 Ne Zaman Veterinere Gidilmeli?")
                        .font(.subheadline.weight(.semibold))

                    ForEach(result.vetWarnings, id: \.self) { warning in
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                            Text(warning)
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))

                // Actions
                VStack(spacing: 10) {
                    ShareLink(item: generateShareText(result)) {
                        Label("Veterinere Gönder", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)

                    Button {
                        saveToBehaviorLog(result)
                    } label: {
                        Label("Kayıtlara Ekle", systemImage: "square.and.pencil")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button("Yeni Analiz") {
                        withAnimation {
                            analysisResult = nil
                            description = ""
                            selectedImageData = nil
                            selectedBodyArea = nil
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
                .padding(.top, 4)
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("AI Analiz Sonucu")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Analysis Engine

    private func performAnalysis() {
        guard !description.isEmpty else { return }
        isAnalyzing = true

        // Simulate AI processing delay (in production, this would call an AI API)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            let result = AISymptomEngine.analyze(
                description: description,
                bodyArea: selectedBodyArea,
                duration: symptomDuration,
                hasPhoto: selectedImageData != nil,
                species: pet.species,
                breed: pet.breed,
                age: pet.age,
                existingConditions: pet.specialConditions,
                allergies: pet.allergies
            )
            withAnimation(.spring(duration: 0.3)) {
                analysisResult = result
                isAnalyzing = false
            }
        }
    }

    private func generateShareText(_ result: AIAnalysisResult) -> String {
        var text = "🤖 AI Semptom Analizi — \(pet.name)\n\n"
        text += "📍 Bölge: \(selectedBodyArea?.rawValue ?? "Belirtilmedi")\n"
        text += "⏱ Süre: \(symptomDuration.rawValue)\n"
        text += "📝 Açıklama: \(description)\n\n"
        text += "⚠️ Aciliyet: \(result.urgency.title)\n"
        text += "📋 Özet: \(result.summary)\n\n"
        text += "Olası Durumlar:\n"
        for c in result.possibleConditions {
            text += "  \(c.emoji) \(c.name) (\(c.likelihood))\n"
        }
        text += "\n— PetLog AI ile oluşturuldu (ön değerlendirmedir, vet tanısı yerine geçmez)"
        return text
    }

    private func saveToBehaviorLog(_ result: AIAnalysisResult) {
        let notes = "AI Analiz: \(result.summary). Bölge: \(selectedBodyArea?.rawValue ?? "–"). Belirtiler: \(description)"
        let severity = result.urgency == .emergency ? 5 : (result.urgency == .high ? 4 : 2)
        store.addBehaviorLog(to: pet, behaviorType: .other, severity: severity, notes: notes, date: Date())
    }

    private func likelihoodColor(_ likelihood: String) -> Color {
        switch likelihood {
        case "Yüksek": return .red
        case "Orta": return .orange
        case "Düşük": return .green
        default: return .secondary
        }
    }
}

// MARK: - AI Analysis Models

struct AIAnalysisResult {
    let urgency: AIUrgency
    let summary: String
    let possibleConditions: [AICondition]
    let immediateActions: [String]
    let vetWarnings: [String]
}

struct AICondition {
    let name: String
    let emoji: String
    let explanation: String
    let likelihood: String  // "Yüksek", "Orta", "Düşük"
}

enum AIUrgency {
    case low, moderate, high, emergency

    var title: String {
        switch self {
        case .low: return "ℹ️ Düşük Risk"
        case .moderate: return "📋 Orta Risk"
        case .high: return "⚠️ Yüksek Risk"
        case .emergency: return "🚨 Acil Durum"
        }
    }

    var description: String {
        switch self {
        case .low: return "Muhtemelen ciddi değil, ancak takip edin"
        case .moderate: return "Birkaç gün içinde veteriner kontrolü önerilir"
        case .high: return "24 saat içinde veterinere gidin"
        case .emergency: return "HEMEN veterinere gidin!"
        }
    }

    var color: Color {
        switch self {
        case .low: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .emergency: return .red
        }
    }

    var icon: String {
        switch self {
        case .low: return "info.circle.fill"
        case .moderate: return "checkmark.shield.fill"
        case .high: return "exclamationmark.triangle.fill"
        case .emergency: return "bolt.heart.fill"
        }
    }
}

// MARK: - AI Symptom Engine (On-Device Rule-Based, upgradeable to LLM API)

struct AISymptomEngine {
    static func analyze(
        description: String,
        bodyArea: AISymptomAnalysisView.BodyArea?,
        duration: AISymptomAnalysisView.SymptomDuration,
        hasPhoto: Bool,
        species: PetSpecies,
        breed: String,
        age: String,
        existingConditions: String,
        allergies: String
    ) -> AIAnalysisResult {

        let desc = description.lowercased()
        var conditions: [AICondition] = []
        var urgency: AIUrgency = .low
        var immediateActions: [String] = []
        var vetWarnings: [String] = []
        var summaryParts: [String] = []

        // MARK: Pattern matching based on description + body area

        // Skin / Deri issues
        if bodyArea == .skin || desc.contains("kaşın") || desc.contains("dökülen") || desc.contains("kızarık") || desc.contains("yara") {
            conditions.append(AICondition(
                name: "Dermatit / Alerji", emoji: "🧴",
                explanation: "Deri iltihabı veya alerjik reaksiyon. Gıda alerjisi, çevresel alerjen veya parazit kaynaklı olabilir.",
                likelihood: desc.contains("şiddet") || desc.contains("çok") ? "Yüksek" : "Orta"
            ))
            if desc.contains("kene") || desc.contains("pire") {
                conditions.append(AICondition(
                    name: "Parazit Enfestasyonu", emoji: "🦠",
                    explanation: "Dış parazit (kene, pire) varlığı. Düzenli antiparaziter tedavi gerektirir.",
                    likelihood: "Yüksek"
                ))
                immediateActions.append("Paraziti çıplak elle çekmeyin, veteriner forsepsi kullanın")
            }
            if desc.contains("yara") || desc.contains("lezyon") || desc.contains("kab") {
                urgency = .moderate
                conditions.append(AICondition(
                    name: "Deri Enfeksiyonu", emoji: "🩹",
                    explanation: "Bakteriyel veya mantar enfeksiyonu. Lezyon büyüyorsa veya koku varsa veteriner gerekli.",
                    likelihood: "Orta"
                ))
            }
            immediateActions.append("Etkilenen bölgeyi temiz tutun, kaşımasını engellemeye çalışın")
            summaryParts.append("Deri/tüy problemi tespit edildi")
        }

        // Eye issues
        if bodyArea == .eyes || desc.contains("göz") || desc.contains("akıntı") || desc.contains("kırmızı göz") {
            conditions.append(AICondition(
                name: "Konjuktivit", emoji: "👁",
                explanation: "Göz iltihabı. Enfeksiyon, alerji veya yabancı cisim kaynaklı olabilir.",
                likelihood: "Orta"
            ))
            if desc.contains("bulanık") || desc.contains("görme") {
                urgency = .high
                conditions.append(AICondition(
                    name: "Göz Hasarı / Glokom", emoji: "🔴",
                    explanation: "Ciddi göz durumu. Görme kaybı riski var. Acil göz muayenesi gerekli.",
                    likelihood: "Orta"
                ))
            }
            immediateActions.append("Gözü temiz suyla yıkayın")
            immediateActions.append("Gözünü kaşımasını engelleyin (koruyucu başlık düşünün)")
            summaryParts.append("Göz problemi tespit edildi")
        }

        // Ears
        if bodyArea == .ears || desc.contains("kulak") || desc.contains("baş sall") || desc.contains("koku") {
            conditions.append(AICondition(
                name: "Otitis (Kulak İltihabı)", emoji: "👂",
                explanation: "Kulak enfeksiyonu olabilir. Sarkık kulaklı ırklarda daha sık görülür.",
                likelihood: "Yüksek"
            ))
            immediateActions.append("Kulağın içine sıvı dökmeyin")
            summaryParts.append("Kulak sorunu tespit edildi")
        }

        // Limping / Paw
        if bodyArea == .legs || bodyArea == .paws || desc.contains("topal") || desc.contains("basmıyor") || desc.contains("aksıyor") || desc.contains("şişlik") {
            conditions.append(AICondition(
                name: "Burkulma / İncinme", emoji: "🦴",
                explanation: "Kas, bağ veya kemik yaralanması. Hafif vakalarda dinlenme ile geçebilir.",
                likelihood: "Yüksek"
            ))
            if desc.contains("kırdı") || desc.contains("çarpma") || desc.contains("düşme") || desc.contains("çok şiş") {
                urgency = .high
                conditions.append(AICondition(
                    name: "Kırık / Çıkık Şüphesi", emoji: "🚑",
                    explanation: "Ciddi travma belirtisi. Röntgen ile değerlendirilmeli.",
                    likelihood: "Orta"
                ))
            }
            immediateActions.append("Aktiviteyi sınırlandırın, dinlenmeye bırakın")
            immediateActions.append("Şişlik varsa soğuk kompres uygulayabilirsiniz (10 dk)")
            summaryParts.append("Hareket/eklem problemi tespit edildi")
        }

        // Belly
        if bodyArea == .belly || desc.contains("karın") || desc.contains("kusma") || desc.contains("ishal") || desc.contains("yemiyor") {
            conditions.append(AICondition(
                name: "Gastrointestinal Rahatsızlık", emoji: "🤢",
                explanation: "Sindirim sistemi sorunu. Yanlış beslenme, enfeksiyon veya stres kaynaklı olabilir.",
                likelihood: "Yüksek"
            ))
            if desc.contains("kan") {
                urgency = .emergency
                conditions.append(AICondition(
                    name: "İç Kanama / Zehirlenme", emoji: "🚨",
                    explanation: "Kanlı kusma/ishal hayati tehlike göstergesi olabilir. ACIL müdahale gerekli.",
                    likelihood: "Yüksek"
                ))
                immediateActions.insert("DERHAL veterinere gidin!", at: 0)
            }
            if species == .dog && desc.contains("şişkin") {
                urgency = .emergency
                conditions.append(AICondition(
                    name: "Gastrik Dilatasyon Volvulus (GDV)", emoji: "🆘",
                    explanation: "Mide dönmesi. Büyük ırk köpeklerde hayati tehlike. Dakikalar önemli!",
                    likelihood: "Orta"
                ))
            }
            immediateActions.append("24 saat hafif diyet deneyin (haşlanmış tavuk + pirinç)")
            immediateActions.append("Dehidrasyon belirtilerini kontrol edin")
            summaryParts.append("Sindirim problemi tespit edildi")
        }

        // Mouth
        if bodyArea == .mouth || desc.contains("diş") || desc.contains("ağız") || desc.contains("salya") || desc.contains("diş eti") {
            conditions.append(AICondition(
                name: "Periodontal Hastalık", emoji: "🦷",
                explanation: "Diş eti iltihabı veya diş çürüğü. Ağız kokusu önemli bir gösterge.",
                likelihood: "Orta"
            ))
            immediateActions.append("Yumuşak mama tercih edin")
            summaryParts.append("Ağız/diş problemi tespit edildi")
        }

        // Breathing
        if bodyArea == .chest || desc.contains("nefes") || desc.contains("öksür") || desc.contains("hırıl") {
            urgency = max(urgency, .high)
            conditions.append(AICondition(
                name: "Solunum Yolu Enfeksiyonu", emoji: "🫁",
                explanation: "Üst veya alt solunum yolu enfeksiyonu. Nefes darlığı acil durumdur.",
                likelihood: "Orta"
            ))
            if desc.contains("morarma") || desc.contains("nefes alam") {
                urgency = .emergency
            }
            summaryParts.append("Solunum problemi tespit edildi")
        }

        // Neurological
        if desc.contains("nöbet") || desc.contains("kasılma") || desc.contains("titreme") || desc.contains("denge") {
            urgency = .emergency
            conditions.append(AICondition(
                name: "Nörolojik Kriz", emoji: "🧠",
                explanation: "Epilepsi, zehirlenme veya beyin hastalığı belirtisi. Nöbet süresini kaydedin.",
                likelihood: "Yüksek"
            ))
            immediateActions.insert("Sakin olun, çevredeki tehlikeli nesneleri kaldırın", at: 0)
            immediateActions.insert("Ağzına hiçbir şey sokmayın", at: 1)
            immediateActions.insert("Nöbet süresini zamanlayın ve kaydedin", at: 2)
            summaryParts.append("Nörolojik belirti tespit edildi")
        }

        // Duration modifier
        switch duration {
        case .twoWeeks, .month:
            if urgency == .low { urgency = .moderate }
            vetWarnings.append("Belirtiler \(duration.rawValue) — kronikleşme riski artıyor")
        case .oneWeek:
            vetWarnings.append("1 haftadır devam eden belirtiler profesyonel değerlendirme gerektirir")
        default: break
        }

        // Age modifier
        if age.contains("yavru") || age.contains("ay") {
            if urgency == .low { urgency = .moderate }
            vetWarnings.append("Yavru hayvanlarda belirtiler daha hızlı ilerleyebilir")
        }

        // Breed-specific
        if !breed.isEmpty {
            if species == .dog && (breed.lowercased().contains("bulldog") || breed.lowercased().contains("pug") || breed.lowercased().contains("pekingese")) {
                if bodyArea == .chest || desc.contains("nefes") {
                    conditions.append(AICondition(
                        name: "Brakisefalik Sendrom", emoji: "🐶",
                        explanation: "\(breed) ırkı düz yüz yapısı nedeniyle solunum sorunlarına yatkındır.",
                        likelihood: "Orta"
                    ))
                }
            }
        }

        // Existing conditions modifier
        if !existingConditions.isEmpty {
            vetWarnings.append("Mevcut durumlar (\(existingConditions)) göz önünde bulundurulmalı")
        }
        if !allergies.isEmpty {
            immediateActions.append("Bilinen alerjiler: \(allergies) — bu alerjenlerle temas olup olmadığını kontrol edin")
        }

        // Default vet warnings
        vetWarnings.append("Belirtiler kötüleşirse veya yeni belirtiler eklenirse")
        vetWarnings.append("Yeme-içmeyi bırakırsa")
        vetWarnings.append("Davranış tamamen değişirse")

        // Fallback
        if conditions.isEmpty {
            conditions.append(AICondition(
                name: "Genel Değerlendirme", emoji: "📋",
                explanation: "Verilen bilgiler kesin bir ön tanı koymaya yeterli değil. Detaylı muayene için veteriner önerilir.",
                likelihood: "–"
            ))
        }

        if summaryParts.isEmpty {
            summaryParts.append("Belirtilen semptomlar genel değerlendirme gerektirir")
        }

        let summary = "\(pet.species.rawValue) türü, \(breed.isEmpty ? "" : "\(breed) ırkı, ")yaş: \(age). \(summaryParts.joined(separator: ". ")). Süre: \(duration.rawValue)."

        return AIAnalysisResult(
            urgency: urgency,
            summary: summary,
            possibleConditions: conditions,
            immediateActions: immediateActions.isEmpty ? ["Belirtileri takip edin ve kaydedin"] : immediateActions,
            vetWarnings: vetWarnings
        )
    }
}

// Helper for urgency comparison
extension AIUrgency: Comparable {
    private var order: Int {
        switch self {
        case .low: return 0
        case .moderate: return 1
        case .high: return 2
        case .emergency: return 3
        }
    }
    static func < (lhs: AIUrgency, rhs: AIUrgency) -> Bool {
        lhs.order < rhs.order
    }
}
