import SwiftUI

struct SymptomCheckerView: View {
    let pet: Pet
    let store: PetStore

    @State private var selectedSymptoms: Set<SymptomItem> = []
    @State private var showResults = false
    @State private var additionalNotes = ""

    private var filteredSymptoms: [SymptomCategory] {
        SymptomDatabase.categories(for: pet.species)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if showResults {
                    resultsView
                } else {
                    symptomSelectionView
                }
            }
            .navigationTitle("Semptom Kontrol")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Symptom Selection

    private var symptomSelectionView: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Text("🩺")
                    .font(.largeTitle)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(pet.name) için semptom seçin")
                        .font(.headline)
                    Text("Gözlemlediğiniz belirtileri işaretleyin")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding()

            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(filteredSymptoms, id: \.name) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(category.emoji) \(category.name)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)

                            FlowLayout(spacing: 8) {
                                ForEach(category.symptoms, id: \.self) { symptom in
                                    Button {
                                        if selectedSymptoms.contains(symptom) {
                                            selectedSymptoms.remove(symptom)
                                        } else {
                                            selectedSymptoms.insert(symptom)
                                        }
                                    } label: {
                                        Text(symptom.name)
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .background(
                                                selectedSymptoms.contains(symptom) ?
                                                urgencyColor(symptom.urgency).opacity(0.15) :
                                                    Color(.tertiarySystemGroupedBackground)
                                            )
                                            .foregroundStyle(
                                                selectedSymptoms.contains(symptom) ?
                                                urgencyColor(symptom.urgency) : .primary
                                            )
                                            .clipShape(Capsule())
                                            .overlay(
                                                Capsule()
                                                    .stroke(
                                                        selectedSymptoms.contains(symptom) ?
                                                            urgencyColor(symptom.urgency) : .clear, lineWidth: 1
                                                    )
                                            )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Ek Notlar")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        TextField("Başka gözlemler...", text: $additionalNotes, axis: .vertical)
                            .lineLimit(2...4)
                            .padding(10)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 10))
                    }
                    .padding(.horizontal)
                }
                .padding(.bottom, 100)
            }

            // Bottom action
            if !selectedSymptoms.isEmpty {
                VStack(spacing: 8) {
                    Text("\(selectedSymptoms.count) semptom seçildi")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Button {
                        withAnimation(.spring(duration: 0.3)) { showResults = true }
                    } label: {
                        Text("Analiz Et")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                }
                .padding()
                .background(.ultraThinMaterial)
            }
        }
    }

    // MARK: - Results

    private var resultsView: some View {
        let analysis = SymptomAnalyzer.analyze(symptoms: Array(selectedSymptoms), species: pet.species, breed: pet.breed)

        return ScrollView {
            VStack(spacing: 16) {
                // Urgency banner
                HStack(spacing: 12) {
                    Image(systemName: analysis.urgency == .emergency ? "exclamationmark.triangle.fill" : "info.circle.fill")
                        .font(.title2)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(analysis.urgencyTitle)
                            .font(.headline)
                        Text(analysis.urgencyDescription)
                            .font(.caption)
                    }
                    Spacer()
                }
                .padding()
                .foregroundStyle(.white)
                .background(urgencyColor(analysis.urgency))
                .clipShape(.rect(cornerRadius: 14))

                // Disclaimer
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.shield.fill")
                        .foregroundStyle(.orange)
                    Text("Bu bir ön değerlendirmedir, profesyonel veteriner tanısı yerine geçmez.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(Color.orange.opacity(0.1))
                .clipShape(.rect(cornerRadius: 10))

                // Selected symptoms summary
                VStack(alignment: .leading, spacing: 8) {
                    Text("Seçilen Semptomlar")
                        .font(.subheadline.weight(.semibold))

                    FlowLayout(spacing: 6) {
                        ForEach(Array(selectedSymptoms), id: \.self) { symptom in
                            Text(symptom.name)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(urgencyColor(symptom.urgency).opacity(0.15))
                                .foregroundStyle(urgencyColor(symptom.urgency))
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))

                // Possible conditions
                if !analysis.possibleConditions.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Olası Durumlar")
                            .font(.subheadline.weight(.semibold))

                        ForEach(analysis.possibleConditions, id: \.name) { condition in
                            HStack(alignment: .top, spacing: 10) {
                                Text(condition.emoji)
                                    .font(.title3)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(condition.name)
                                        .font(.subheadline.weight(.semibold))
                                    Text(condition.description)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if condition.name != analysis.possibleConditions.last?.name {
                                Divider()
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 12))
                }

                // Recommendations
                VStack(alignment: .leading, spacing: 10) {
                    Text("Öneriler")
                        .font(.subheadline.weight(.semibold))

                    ForEach(analysis.recommendations, id: \.self) { rec in
                        HStack(alignment: .top, spacing: 8) {
                            Text("•")
                                .foregroundStyle(.blue)
                            Text(rec)
                                .font(.caption)
                        }
                    }
                }
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 12))

                // Actions
                VStack(spacing: 10) {
                    // Share with vet
                    ShareLink(item: generateShareText(analysis: analysis)) {
                        Label("Veterinere Gönder", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)

                    // Save as behavior log
                    Button {
                        saveToBehaviorLog()
                        withAnimation { showResults = false }
                        selectedSymptoms.removeAll()
                    } label: {
                        Label("Davranış Kaydına Ekle", systemImage: "square.and.pencil")
                            .font(.subheadline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)

                    Button("Yeni Kontrol") {
                        withAnimation { showResults = false }
                        selectedSymptoms.removeAll()
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Helpers

    private func urgencyColor(_ urgency: SymptomUrgency) -> Color {
        switch urgency {
        case .low: return .green
        case .medium: return .yellow
        case .high: return .orange
        case .emergency: return .red
        }
    }

    private func generateShareText(analysis: SymptomAnalyzer.Analysis) -> String {
        var text = "🩺 \(pet.name) Semptom Raporu\n\n"
        text += "Semptomlar: \(selectedSymptoms.map(\.name).joined(separator: ", "))\n"
        if !additionalNotes.isEmpty { text += "Notlar: \(additionalNotes)\n" }
        text += "\nAciliyet: \(analysis.urgencyTitle)\n"
        text += "\nOlası Durumlar:\n"
        for c in analysis.possibleConditions {
            text += "  \(c.emoji) \(c.name): \(c.description)\n"
        }
        text += "\n— PetLog ile oluşturuldu"
        return text
    }

    private func saveToBehaviorLog() {
        let symptomsText = selectedSymptoms.map(\.name).joined(separator: ", ")
        let notes = "Semptomlar: \(symptomsText). \(additionalNotes)"
        let severity = selectedSymptoms.map(\.urgency.numericValue).max() ?? 2
        store.addBehaviorLog(to: pet, behaviorType: .other, severity: severity, notes: notes, date: Date())
    }
}

// MARK: - Flow Layout

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, position) in result.positions.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (positions: [CGPoint], size: CGSize) {
        let maxWidth = proposal.width ?? .infinity
        var positions: [CGPoint] = []
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth && x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            positions.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }

        return (positions, CGSize(width: maxWidth, height: y + rowHeight))
    }
}

// MARK: - Symptom Data

enum SymptomUrgency: Int, Comparable {
    case low = 1, medium = 2, high = 3, emergency = 4

    static func < (lhs: SymptomUrgency, rhs: SymptomUrgency) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var numericValue: Int { rawValue }
}

struct SymptomItem: Hashable {
    let name: String
    let urgency: SymptomUrgency
}

struct SymptomCategory {
    let name: String
    let emoji: String
    let symptoms: [SymptomItem]
}

struct SymptomDatabase {
    static func categories(for species: PetSpecies) -> [SymptomCategory] {
        var cats: [SymptomCategory] = []

        cats.append(SymptomCategory(name: "Sindirim", emoji: "🤢", symptoms: [
            SymptomItem(name: "Kusma", urgency: .medium),
            SymptomItem(name: "İshal", urgency: .medium),
            SymptomItem(name: "Kabızlık", urgency: .low),
            SymptomItem(name: "İştahsızlık", urgency: .medium),
            SymptomItem(name: "Aşırı yeme", urgency: .low),
            SymptomItem(name: "Kanlı dışkı", urgency: .emergency),
            SymptomItem(name: "Kanlı kusma", urgency: .emergency),
        ]))

        cats.append(SymptomCategory(name: "Hareket", emoji: "🦿", symptoms: [
            SymptomItem(name: "Topallama", urgency: .medium),
            SymptomItem(name: "Hareket zorluğu", urgency: .high),
            SymptomItem(name: "Ataksi (denge kaybı)", urgency: .emergency),
            SymptomItem(name: "Arka ayak zayıflığı", urgency: .high),
            SymptomItem(name: "Şişlik", urgency: .medium),
        ]))

        cats.append(SymptomCategory(name: "Solunum", emoji: "🫁", symptoms: [
            SymptomItem(name: "Öksürük", urgency: .medium),
            SymptomItem(name: "Hapşırma", urgency: .low),
            SymptomItem(name: "Burun akıntısı", urgency: .low),
            SymptomItem(name: "Nefes darlığı", urgency: .emergency),
            SymptomItem(name: "Hırıltı", urgency: .high),
        ]))

        cats.append(SymptomCategory(name: "Deri & Tüy", emoji: "🧴", symptoms: [
            SymptomItem(name: "Aşırı kaşınma", urgency: .medium),
            SymptomItem(name: "Tüy dökülmesi", urgency: .low),
            SymptomItem(name: "Kızarıklık", urgency: .medium),
            SymptomItem(name: "Yara / Lezyon", urgency: .high),
            SymptomItem(name: "Kene / Pire", urgency: .medium),
        ]))

        cats.append(SymptomCategory(name: "Davranış", emoji: "🧠", symptoms: [
            SymptomItem(name: "Halsizlik", urgency: .medium),
            SymptomItem(name: "Aşırı susama", urgency: .high),
            SymptomItem(name: "Aşırı idrara çıkma", urgency: .high),
            SymptomItem(name: "Agresiflik", urgency: .medium),
            SymptomItem(name: "Titreme", urgency: .high),
            SymptomItem(name: "Nöbet / Kasılma", urgency: .emergency),
        ]))

        cats.append(SymptomCategory(name: "Göz & Kulak", emoji: "👁", symptoms: [
            SymptomItem(name: "Göz akıntısı", urgency: .low),
            SymptomItem(name: "Kırmızı göz", urgency: .medium),
            SymptomItem(name: "Kulak kokusu", urgency: .medium),
            SymptomItem(name: "Baş sallama", urgency: .medium),
            SymptomItem(name: "Göz bulanıklığı", urgency: .high),
        ]))

        if species == .cat {
            cats.append(SymptomCategory(name: "Kedi Özel", emoji: "🐱", symptoms: [
                SymptomItem(name: "Kum dışı idrar", urgency: .high),
                SymptomItem(name: "İdrar yolları", urgency: .emergency),
                SymptomItem(name: "Aşırı tımar", urgency: .medium),
                SymptomItem(name: "Saklanma", urgency: .medium),
            ]))
        }

        if species == .dog {
            cats.append(SymptomCategory(name: "Köpek Özel", emoji: "🐶", symptoms: [
                SymptomItem(name: "Karın şişliği", urgency: .emergency),
                SymptomItem(name: "Çok havlama", urgency: .low),
                SymptomItem(name: "Kuyruk kovalama", urgency: .medium),
                SymptomItem(name: "Salya akması", urgency: .medium),
            ]))
        }

        return cats
    }
}

// MARK: - Symptom Analyzer

struct SymptomAnalyzer {
    struct Analysis {
        let urgency: SymptomUrgency
        let urgencyTitle: String
        let urgencyDescription: String
        let possibleConditions: [Condition]
        let recommendations: [String]
    }

    struct Condition {
        let name: String
        let emoji: String
        let description: String
    }

    static func analyze(symptoms: [SymptomItem], species: PetSpecies, breed: String) -> Analysis {
        let maxUrgency = symptoms.map(\.urgency).max() ?? .low
        let symptomNames = Set(symptoms.map(\.name))

        var conditions: [Condition] = []
        var recommendations: [String] = []

        // Urgency text
        let urgencyTitle: String
        let urgencyDesc: String
        switch maxUrgency {
        case .emergency:
            urgencyTitle = "🚨 Acil Durum"
            urgencyDesc = "Bu belirtiler ciddi olabilir. Hemen veteriner ile iletişime geçin!"
        case .high:
            urgencyTitle = "⚠️ Dikkat Gerekli"
            urgencyDesc = "24 saat içinde veteriner kontrolü önerilir."
        case .medium:
            urgencyTitle = "📋 İzlenmeli"
            urgencyDesc = "Belirtileri takip edin, devam ederse veterinere başvurun."
        case .low:
            urgencyTitle = "ℹ️ Hafif Belirti"
            urgencyDesc = "Muhtemelen ciddi değil, ancak devam ederse kontrol ettirin."
        }

        // Pattern matching for conditions
        if symptomNames.contains("Kusma") && symptomNames.contains("İshal") {
            conditions.append(Condition(name: "Gastroenterit", emoji: "🤢", description: "Sindirim sistemi enfeksiyonu veya besin intoleransı olabilir."))
            recommendations.append("24 saat boyunca hafif diyet (haşlanmış tavuk + pirinç) deneyin")
        }

        if symptomNames.contains("Kanlı dışkı") || symptomNames.contains("Kanlı kusma") {
            conditions.append(Condition(name: "İç Kanama / Zehirlenme", emoji: "🚨", description: "Ciddi iç kanama veya zehirlenme belirtisi olabilir."))
            recommendations.append("ACIL veteriner müdahalesi gerekir, beklemeyin!")
        }

        if symptomNames.contains("Aşırı susama") && symptomNames.contains("Aşırı idrara çıkma") {
            conditions.append(Condition(name: "Böbrek / Diyabet Şüphesi", emoji: "💧", description: "Poliüri-polidipsi sendromu. Böbrek yetmezliği veya diyabet olabilir."))
            recommendations.append("En kısa sürede kan ve idrar testi yaptırın")
        }

        if symptomNames.contains("İştahsızlık") && symptomNames.contains("Halsizlik") {
            conditions.append(Condition(name: "Enfeksiyon / Ateş", emoji: "🤒", description: "Genel enfeksiyon belirtisi olabilir."))
            recommendations.append("Ateş ölçün (normal: 38-39°C). Yüksekse veterinere başvurun")
        }

        if symptomNames.contains("Öksürük") && species == .dog {
            conditions.append(Condition(name: "Kulübe Öksürüğü", emoji: "🫁", description: "Kennel cough (Bordetella) olabilir. Bulaşıcıdır."))
            recommendations.append("Diğer hayvanlardan izole edin")
        }

        if symptomNames.contains("Aşırı kaşınma") {
            conditions.append(Condition(name: "Alerji / Parazit", emoji: "🧴", description: "Deri alerjisi, pire veya mantar enfeksiyonu olabilir."))
            recommendations.append("Pire kontrolü yapın. Diyet değişikliği düşünün")
        }

        if symptomNames.contains("Nöbet / Kasılma") {
            conditions.append(Condition(name: "Epilepsi / Nörolojik", emoji: "🧠", description: "Ciddi nörolojik durum. Nöbet süresini kaydedin."))
            recommendations.append("Nöbet sırasında sakin olun, ağzına bir şey sokmayın, kaydedin")
        }

        if symptomNames.contains("Topallama") || symptomNames.contains("Şişlik") {
            conditions.append(Condition(name: "Ortopedik Sorun", emoji: "🦴", description: "Burkulma, kırık veya eklem sorunu olabilir."))
            recommendations.append("Aktiviteyi sınırlandırın, etkilenen bölgeyi soğuk kompres yapabilirsiniz")
        }

        if symptomNames.contains("Karın şişliği") && species == .dog {
            conditions.append(Condition(name: "Mide Dönmesi (GDV)", emoji: "🚨", description: "Hayati tehlike! Mide dönmesi acil cerrahi gerektirebilir."))
            recommendations.append("DERHAL veterinere gidin, dakikalar hayati önem taşır!")
        }

        // Generic recommendations
        recommendations.append("Belirtiler devam ederse veya kötüleşirse veterinere başvurun")
        recommendations.append("Belirtilerin başlangıç zamanını not edin")

        if conditions.isEmpty {
            conditions.append(Condition(name: "Genel Değerlendirme", emoji: "📋", description: "Belirtilen semptomlar çeşitli durumlardan kaynaklanabilir. Detaylı teşhis için veteriner muayenesi önerilir."))
        }

        return Analysis(
            urgency: maxUrgency,
            urgencyTitle: urgencyTitle,
            urgencyDescription: urgencyDesc,
            possibleConditions: conditions,
            recommendations: recommendations
        )
    }
}
