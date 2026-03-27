import Foundation
import SwiftUI

/// Calculates a 0-100 wellness score based on multiple health/care dimensions.
/// Each dimension is weighted and scored independently, then combined.
struct WellnessScoreEngine {

    struct ScoreResult {
        let overall: Int  // 0-100
        let dimensions: [Dimension]
        let grade: Grade
        let tip: String
    }

    struct Dimension {
        let name: String
        let emoji: String
        let score: Int   // 0-100
        let weight: Double
        let detail: String
    }

    enum Grade: String {
        case excellent = "Mükemmel"
        case good = "İyi"
        case fair = "Orta"
        case needsAttention = "Dikkat"
        case critical = "Kritik"

        var color: Color {
            switch self {
            case .excellent: return .green
            case .good: return .blue
            case .fair: return .yellow
            case .needsAttention: return .orange
            case .critical: return .red
            }
        }

        var emoji: String {
            switch self {
            case .excellent: return "🌟"
            case .good: return "😊"
            case .fair: return "😐"
            case .needsAttention: return "⚠️"
            case .critical: return "🚨"
            }
        }
    }

    static func calculate(for pet: Pet) -> ScoreResult {
        let calendar = Calendar.current
        let now = Date()

        var dimensions: [Dimension] = []

        // 1. Vaccination Score (weight: 0.25)
        let vaccScore = vaccinationScore(pet: pet)
        dimensions.append(Dimension(
            name: "Aşılar", emoji: "💉", score: vaccScore.score,
            weight: 0.25, detail: vaccScore.detail
        ))

        // 2. Weight Health (weight: 0.20)
        let weightScore = weightHealthScore(pet: pet)
        dimensions.append(Dimension(
            name: "Kilo", emoji: "⚖️", score: weightScore.score,
            weight: 0.20, detail: weightScore.detail
        ))

        // 3. Activity Level (weight: 0.15)
        let actScore = activityScore(pet: pet, calendar: calendar, now: now)
        dimensions.append(Dimension(
            name: "Aktivite", emoji: "🏃", score: actScore.score,
            weight: 0.15, detail: actScore.detail
        ))

        // 4. Nutrition Tracking (weight: 0.15)
        let nutScore = nutritionScore(pet: pet, calendar: calendar, now: now)
        dimensions.append(Dimension(
            name: "Beslenme", emoji: "🍽", score: nutScore.score,
            weight: 0.15, detail: nutScore.detail
        ))

        // 5. Vet Visits (weight: 0.15)
        let vetScore = vetVisitScore(pet: pet, calendar: calendar, now: now)
        dimensions.append(Dimension(
            name: "Veteriner", emoji: "🏥", score: vetScore.score,
            weight: 0.15, detail: vetScore.detail
        ))

        // 6. Care Consistency (weight: 0.10)
        let careScore = careConsistencyScore(pet: pet, calendar: calendar, now: now)
        dimensions.append(Dimension(
            name: "Bakım", emoji: "🧴", score: careScore.score,
            weight: 0.10, detail: careScore.detail
        ))

        // Calculate weighted overall
        let overall = Int(dimensions.reduce(0.0) { $0 + Double($1.score) * $1.weight })
        let clamped = max(0, min(100, overall))
        let grade = gradeFor(clamped)

        // Generate tip based on lowest dimension
        let lowest = dimensions.min(by: { $0.score < $1.score })
        let tip = generateTip(for: lowest, petName: pet.name)

        return ScoreResult(overall: clamped, dimensions: dimensions, grade: grade, tip: tip)
    }

    // MARK: - Dimension Calculators

    private static func vaccinationScore(pet: Pet) -> (score: Int, detail: String) {
        let total = pet.vaccineRecords.count
        guard total > 0 else { return (30, "Henüz aşı kaydı yok") }

        let overdue = pet.vaccineRecords.filter { $0.isOverdue }.count
        let upToDate = total - overdue
        let ratio = Double(upToDate) / Double(total)

        if overdue == 0 {
            return (100, "Tüm aşılar güncel ✓")
        } else {
            return (Int(ratio * 70) + 20, "\(overdue) aşı gecikmiş")
        }
    }

    private static func weightHealthScore(pet: Pet) -> (score: Int, detail: String) {
        guard let current = pet.latestWeight else {
            return (50, "Kilo kaydı yok")
        }

        if let target = pet.weightTargetKg {
            let deviation = abs(current - target) / target
            if deviation < 0.05 { return (100, "Hedef kiloda (\(String(format: "%.1f", current)) kg)") }
            if deviation < 0.10 { return (85, "Hedefe yakın (\(String(format: "%.1f", current)) kg)") }
            if deviation < 0.20 { return (65, "%\(Int(deviation * 100)) sapma") }
            return (40, "Önemli kilo sapması")
        }

        // No target — score based on having regular recordings
        let recentLogs = pet.weightLogs.filter {
            Calendar.current.dateComponents([.month], from: $0.date, to: Date()).month ?? 99 < 3
        }
        if recentLogs.count >= 2 { return (80, "Düzenli takip ediliyor") }
        if recentLogs.count == 1 { return (65, "Son 3 ayda 1 kayıt") }
        return (40, "Uzun süredir kilo kaydı yok")
    }

    private static func activityScore(pet: Pet, calendar: Calendar, now: Date) -> (score: Int, detail: String) {
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let weeklyActivities = pet.activityLogs.filter { $0.date >= weekAgo }
        let totalMinutes = weeklyActivities.reduce(0) { $0 + $1.durationMinutes }

        // Species-based thresholds
        let idealMinutes: Int
        switch pet.species {
        case .dog: idealMinutes = 210  // 30 min/day
        case .cat: idealMinutes = 105  // 15 min/day
        case .rabbit: idealMinutes = 70
        default: idealMinutes = 30
        }

        let ratio = min(1.0, Double(totalMinutes) / Double(idealMinutes))
        let score = Int(ratio * 100)
        return (score, "\(totalMinutes) dk/hafta (ideal: \(idealMinutes) dk)")
    }

    private static func nutritionScore(pet: Pet, calendar: Calendar, now: Date) -> (score: Int, detail: String) {
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let weeklyFeedings = pet.feedingLogs.filter { $0.date >= weekAgo }.count

        // Ideal: at least 2 feedings per day = 14/week
        let idealFeedings = 14
        let ratio = min(1.0, Double(weeklyFeedings) / Double(idealFeedings))
        let score = Int(ratio * 100)

        if weeklyFeedings == 0 { return (30, "Bu hafta beslenme kaydı yok") }
        if ratio >= 0.8 { return (score, "\(weeklyFeedings) öğün/hafta ✓") }
        return (score, "\(weeklyFeedings)/\(idealFeedings) öğün kaydedilmiş")
    }

    private static func vetVisitScore(pet: Pet, calendar: Calendar, now: Date) -> (score: Int, detail: String) {
        guard let lastVisit = pet.vetVisits.sorted(by: { $0.date > $1.date }).first else {
            return (30, "Henüz veteriner ziyareti yok")
        }

        let monthsSince = calendar.dateComponents([.month], from: lastVisit.date, to: now).month ?? 99
        if monthsSince <= 6 { return (100, "Son kontrol \(monthsSince) ay önce ✓") }
        if monthsSince <= 12 { return (70, "Son kontrol \(monthsSince) ay önce") }
        return (40, "\(monthsSince) aydır veteriner ziyareti yok")
    }

    private static func careConsistencyScore(pet: Pet, calendar: Calendar, now: Date) -> (score: Int, detail: String) {
        let monthAgo = calendar.date(byAdding: .month, value: -1, to: now) ?? now

        var factors = 0
        let totalFactors = 4

        // Has recent weight log
        if pet.weightLogs.contains(where: { $0.date >= monthAgo }) { factors += 1 }
        // Has recent feeding log
        if pet.feedingLogs.contains(where: { $0.date >= monthAgo }) { factors += 1 }
        // Has current food set
        if pet.currentFood != nil { factors += 1 }
        // Has photos in last 3 months
        let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now) ?? now
        if pet.photoLogs.contains(where: { $0.date >= threeMonthsAgo }) { factors += 1 }

        let score = Int((Double(factors) / Double(totalFactors)) * 100)
        return (score, "\(factors)/\(totalFactors) bakım kriteri karşılanıyor")
    }

    // MARK: - Helpers

    private static func gradeFor(_ score: Int) -> Grade {
        switch score {
        case 90...100: return .excellent
        case 75..<90: return .good
        case 60..<75: return .fair
        case 40..<60: return .needsAttention
        default: return .critical
        }
    }

    private static func generateTip(for dimension: Dimension?, petName: String) -> String {
        guard let dim = dimension else { return "\(petName) harika görünüyor!" }
        switch dim.name {
        case "Aşılar": return "Gecikmiş aşılar için veteriner randevusu alın."
        case "Kilo": return "Düzenli kilo takibi sağlık sorunlarını erken yakalar."
        case "Aktivite": return "Günlük aktivite süresini artırmayı deneyin."
        case "Beslenme": return "Öğünleri düzenli kaydetmek beslenme düzenini görmeye yardımcı olur."
        case "Veteriner": return "Düzenli sağlık kontrolü için veteriner randevusu alın."
        case "Bakım": return "Daha fazla bakım kaydı tutarak skoru yükseltin."
        default: return "\(petName) ile ilgilenmeye devam edin!"
        }
    }
}
