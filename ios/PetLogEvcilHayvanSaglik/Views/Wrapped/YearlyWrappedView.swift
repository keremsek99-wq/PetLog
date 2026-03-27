import SwiftUI

struct YearlyWrappedView: View {
    let pet: Pet
    let store: PetStore

    @Environment(\.dismiss) private var dismiss
    @State private var currentSlide = 0

    private var stats: WrappedStats {
        calculateStats()
    }

    private let totalSlides = 7

    var body: some View {
        ZStack {
            // Background gradient based on slide
            backgroundGradient
                .ignoresSafeArea()

            VStack {
                // Progress dots
                HStack(spacing: 6) {
                    ForEach(0..<totalSlides, id: \.self) { i in
                        Capsule()
                            .fill(i <= currentSlide ? .white : .white.opacity(0.3))
                            .frame(width: i == currentSlide ? 24 : 8, height: 4)
                    }
                }
                .padding(.top, 16)

                Spacer()

                // Content slides
                TabView(selection: $currentSlide) {
                    introSlide.tag(0)
                    weightSlide.tag(1)
                    healthSlide.tag(2)
                    activitySlide.tag(3)
                    spendingSlide.tag(4)
                    memoriesSlide.tag(5)
                    summarySlide.tag(6)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Spacer()

                // Navigation
                HStack {
                    if currentSlide > 0 {
                        Button {
                            withAnimation(.spring(duration: 0.3)) { currentSlide -= 1 }
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    Spacer()
                    if currentSlide < totalSlides - 1 {
                        Button {
                            withAnimation(.spring(duration: 0.3)) { currentSlide += 1 }
                        } label: {
                            HStack {
                                Text("Devam")
                                    .font(.headline)
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.title)
                            }
                            .foregroundStyle(.white)
                        }
                    } else {
                        ShareLink(item: generateShareText()) {
                            Label("Paylaş", systemImage: "square.and.arrow.up")
                                .font(.headline)
                                .foregroundStyle(.white)
                                .padding(.horizontal, 20)
                                .padding(.vertical, 10)
                                .background(.white.opacity(0.2))
                                .clipShape(Capsule())
                        }

                        Button("Kapat") { dismiss() }
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.leading, 12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
    }

    // MARK: - Background

    private var backgroundGradient: some View {
        let colors: [Color] = switch currentSlide {
        case 0: [.indigo, .purple]
        case 1: [.teal, .blue]
        case 2: [.red, .pink]
        case 3: [.green, .teal]
        case 4: [.orange, .red]
        case 5: [.purple, .pink]
        default: [.blue, .indigo]
        }
        return LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .animation(.easeInOut(duration: 0.4), value: currentSlide)
    }

    // MARK: - Slides

    private var introSlide: some View {
        VStack(spacing: 20) {
            Text(pet.emoji)
                .font(.system(size: 80))

            Text("\(pet.name) ile")
                .font(.title.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))

            Text(Calendar.current.component(.year, from: Date()).description)
                .font(.system(size: 64, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("yılı nasıl geçti?")
                .font(.title2.weight(.medium))
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    private var weightSlide: some View {
        VStack(spacing: 24) {
            Text("⚖️")
                .font(.system(size: 56))

            Text("Kilo Yolculuğu")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)

            if let first = stats.firstWeight, let last = stats.lastWeight {
                HStack(spacing: 24) {
                    VStack {
                        Text(String(format: "%.1f", first))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Text("kg (başlangıç)")
                            .font(.caption)
                    }
                    Image(systemName: "arrow.right")
                        .font(.title2)
                    VStack {
                        Text(String(format: "%.1f", last))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                        Text("kg (şimdi)")
                            .font(.caption)
                    }
                }
                .foregroundStyle(.white)

                Text("\(stats.weightLogCount) kez tartıldı")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.7))
            } else {
                Text("Bu yıl kilo kaydı yok")
                    .font(.title3)
                    .foregroundStyle(.white.opacity(0.7))
            }
        }
    }

    private var healthSlide: some View {
        VStack(spacing: 24) {
            Text("💉")
                .font(.system(size: 56))

            Text("Sağlık Bakımı")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)

            HStack(spacing: 32) {
                statBubble(value: "\(stats.vaccineCount)", label: "aşı")
                statBubble(value: "\(stats.vetVisitCount)", label: "vet ziyareti")
                statBubble(value: "\(stats.medicationCount)", label: "ilaç")
            }
        }
    }

    private var activitySlide: some View {
        VStack(spacing: 24) {
            Text("🏃")
                .font(.system(size: 56))

            Text("Aktivite Özeti")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)

            VStack(spacing: 16) {
                statBubble(value: "\(stats.totalActivityMinutes)", label: "dakika aktivite")
                statBubble(value: "\(stats.feedingCount)", label: "öğün kaydı")
            }
        }
    }

    private var spendingSlide: some View {
        VStack(spacing: 24) {
            Text("💰")
                .font(.system(size: 56))

            Text("Harcama Özeti")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)

            Text(stats.totalSpending.formatted(.currency(code: "TRY")))
                .font(.system(size: 40, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text("toplam harcama")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.7))

            if let topCategory = stats.topExpenseCategory {
                Text("En çok: \(topCategory)")
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.2))
                    .clipShape(Capsule())
                    .foregroundStyle(.white)
            }
        }
    }

    private var memoriesSlide: some View {
        VStack(spacing: 24) {
            Text("📸")
                .font(.system(size: 56))

            Text("Anılar")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)

            HStack(spacing: 32) {
                statBubble(value: "\(stats.photoCount)", label: "fotoğraf")
                statBubble(value: "\(stats.milestoneCount)", label: "anı")
            }
        }
    }

    private var summarySlide: some View {
        VStack(spacing: 20) {
            Text(pet.emoji)
                .font(.system(size: 56))

            Text("\(pet.name) ile harika bir yıl!")
                .font(.title.weight(.bold))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)

            // Wellness score
            let score = WellnessScoreEngine.calculate(for: pet)
            ZStack {
                Circle()
                    .stroke(.white.opacity(0.3), lineWidth: 8)
                    .frame(width: 100, height: 100)
                Circle()
                    .trim(from: 0, to: Double(score.overall) / 100)
                    .stroke(.white, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .frame(width: 100, height: 100)
                    .rotationEffect(.degrees(-90))
                VStack {
                    Text("\(score.overall)")
                        .font(.system(.title, design: .rounded, weight: .bold))
                    Text("wellness")
                        .font(.caption2)
                }
                .foregroundStyle(.white)
            }

            Text(score.grade.rawValue)
                .font(.headline)
                .foregroundStyle(.white.opacity(0.8))
        }
    }

    // MARK: - Helpers

    private func statBubble(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text(label)
                .font(.caption)
                .opacity(0.7)
        }
        .foregroundStyle(.white)
    }

    private func generateShareText() -> String {
        var text = "🐾 \(pet.name) ile \(Calendar.current.component(.year, from: Date())) Yılı\n\n"
        if let w = stats.lastWeight { text += "⚖️ Kilo: \(String(format: "%.1f", w)) kg\n" }
        text += "💉 \(stats.vaccineCount) aşı | 🏥 \(stats.vetVisitCount) vet ziyareti\n"
        text += "🏃 \(stats.totalActivityMinutes) dk aktivite\n"
        text += "💰 \(stats.totalSpending.formatted(.currency(code: "TRY"))) harcama\n"
        text += "📸 \(stats.photoCount) fotoğraf | ⭐ \(stats.milestoneCount) anı\n"
        let score = WellnessScoreEngine.calculate(for: pet)
        text += "📊 Wellness: \(score.overall)/100 (\(score.grade.rawValue))\n"
        text += "\n— PetLog ile oluşturuldu"
        return text
    }

    // MARK: - Stats

    private struct WrappedStats {
        var firstWeight: Double?
        var lastWeight: Double?
        var weightLogCount: Int
        var vaccineCount: Int
        var vetVisitCount: Int
        var medicationCount: Int
        var totalActivityMinutes: Int
        var feedingCount: Int
        var totalSpending: Double
        var topExpenseCategory: String?
        var photoCount: Int
        var milestoneCount: Int
    }

    private func calculateStats() -> WrappedStats {
        let calendar = Calendar.current
        let year = calendar.component(.year, from: Date())
        let startOfYear = calendar.date(from: DateComponents(year: year, month: 1, day: 1)) ?? Date()

        let yearWeights = pet.weightLogs.filter { $0.date >= startOfYear }.sorted { $0.date < $1.date }
        let yearExpenses = pet.expenses.filter { $0.date >= startOfYear }

        // Top expense category
        var catTotals: [String: Double] = [:]
        for e in yearExpenses { catTotals[e.category.rawValue, default: 0] += e.amount }

        return WrappedStats(
            firstWeight: yearWeights.first?.weightKg,
            lastWeight: yearWeights.last?.weightKg,
            weightLogCount: yearWeights.count,
            vaccineCount: pet.vaccineRecords.filter { $0.dateAdministered >= startOfYear }.count,
            vetVisitCount: pet.vetVisits.filter { $0.date >= startOfYear }.count,
            medicationCount: pet.medications.filter { $0.startDate >= startOfYear }.count,
            totalActivityMinutes: pet.activityLogs.filter { $0.date >= startOfYear }.reduce(0) { $0 + $1.durationMinutes },
            feedingCount: pet.feedingLogs.filter { $0.date >= startOfYear }.count,
            totalSpending: yearExpenses.reduce(0) { $0 + $1.amount },
            topExpenseCategory: catTotals.max(by: { $0.value < $1.value })?.key,
            photoCount: pet.photoLogs.filter { $0.date >= startOfYear }.count,
            milestoneCount: pet.milestones.filter { $0.date >= startOfYear }.count
        )
    }
}
