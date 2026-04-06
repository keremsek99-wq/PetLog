import Foundation
import SwiftUI

// MARK: - Trend Data Models

struct TrendComparison {
    let label: String
    let icon: String
    let currentValue: Double
    let previousValue: Double
    let unit: String
    let isHigherBetter: Bool?  // nil = neutral, true = higher is good, false = lower is good
    
    var changePercent: Double {
        guard previousValue > 0 else { return currentValue > 0 ? 100 : 0 }
        return ((currentValue - previousValue) / previousValue) * 100
    }
    
    var changeDirection: TrendDirection {
        if abs(changePercent) < 5 { return .stable }
        return changePercent > 0 ? .up : .down
    }
    
    var isAlarming: Bool {
        guard let isHigherBetter else { return false }
        switch (changeDirection, isHigherBetter) {
        case (.up, false): return abs(changePercent) > 20
        case (.down, true): return abs(changePercent) > 20
        default: return false
        }
    }
    
    enum TrendDirection {
        case up, down, stable
        
        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "arrow.right"
            }
        }
        
        var color: Color {
            switch self {
            case .up: return .orange
            case .down: return .blue
            case .stable: return .green
            }
        }
    }
}

struct TrendAlert: Identifiable {
    let id = UUID()
    let emoji: String
    let title: String
    let message: String
    let severity: AlertSeverity
    
    enum AlertSeverity: Int {
        case info = 0
        case warning = 1
        case critical = 2
        
        var color: Color {
            switch self {
            case .info: return .blue
            case .warning: return .orange
            case .critical: return .red
            }
        }
    }
}

// MARK: - Trend Analyzer Engine

struct TrendAnalyzer {
    
    /// Compare this week vs last week across all key metrics for the pet.
    static func weeklyTrends(for pet: Pet) -> [TrendComparison] {
        let calendar = Calendar.current
        let now = Date()
        let thisWeekStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let lastWeekStart = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        
        var trends: [TrendComparison] = []
        
        // 1. Feeding count
        let thisWeekFeedings = Double(pet.feedingLogs.filter { $0.date >= thisWeekStart }.count)
        let lastWeekFeedings = Double(pet.feedingLogs.filter { $0.date >= lastWeekStart && $0.date < thisWeekStart }.count)
        trends.append(TrendComparison(
            label: "Beslenme", icon: "fork.knife",
            currentValue: thisWeekFeedings, previousValue: lastWeekFeedings,
            unit: "öğün", isHigherBetter: nil
        ))
        
        // 2. Activity minutes (dogs primarily)
        if pet.species == .dog {
            let thisWeekWalkMin = Double(pet.activityLogs.filter { $0.date >= thisWeekStart && $0.activityType == .walk }.reduce(0) { $0 + $1.durationMinutes })
            let lastWeekWalkMin = Double(pet.activityLogs.filter { $0.date >= lastWeekStart && $0.date < thisWeekStart && $0.activityType == .walk }.reduce(0) { $0 + $1.durationMinutes })
            trends.append(TrendComparison(
                label: "Yürüyüş", icon: "figure.walk",
                currentValue: thisWeekWalkMin, previousValue: lastWeekWalkMin,
                unit: "dk", isHigherBetter: true
            ))
        }
        
        // 3. Total activities
        let thisWeekActivities = Double(pet.activityLogs.filter { $0.date >= thisWeekStart }.count)
        let lastWeekActivities = Double(pet.activityLogs.filter { $0.date >= lastWeekStart && $0.date < thisWeekStart }.count)
        trends.append(TrendComparison(
            label: "Aktivite", icon: "flame.fill",
            currentValue: thisWeekActivities, previousValue: lastWeekActivities,
            unit: "kayıt", isHigherBetter: true
        ))
        
        // 4. Behavior incidents (high severity)
        let thisWeekBehaviors = Double(pet.behaviorLogs.filter { $0.date >= thisWeekStart && $0.severity >= 3 }.count)
        let lastWeekBehaviors = Double(pet.behaviorLogs.filter { $0.date >= lastWeekStart && $0.date < thisWeekStart && $0.severity >= 3 }.count)
        trends.append(TrendComparison(
            label: "Semptom", icon: "exclamationmark.triangle.fill",
            currentValue: thisWeekBehaviors, previousValue: lastWeekBehaviors,
            unit: "kayıt", isHigherBetter: false
        ))
        
        // 5. Spending
        let thisWeekSpending = pet.expenses.filter { $0.date >= thisWeekStart }.reduce(0.0) { $0 + $1.amount }
        let lastWeekSpending = pet.expenses.filter { $0.date >= lastWeekStart && $0.date < thisWeekStart }.reduce(0.0) { $0 + $1.amount }
        trends.append(TrendComparison(
            label: "Harcama", icon: "turkishlirasign.circle.fill",
            currentValue: thisWeekSpending, previousValue: lastWeekSpending,
            unit: "₺", isHigherBetter: nil
        ))
        
        return trends
    }
    
    /// Generate trend-based alerts that highlight concerning patterns.
    static func trendAlerts(for pet: Pet) -> [TrendAlert] {
        var alerts: [TrendAlert] = []
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        let fourteenDaysAgo = calendar.date(byAdding: .day, value: -14, to: now) ?? now
        
        // 1. Feeding decline
        let thisWeekFeedings = pet.feedingLogs.filter { $0.date >= sevenDaysAgo }.count
        let lastWeekFeedings = pet.feedingLogs.filter { $0.date >= fourteenDaysAgo && $0.date < sevenDaysAgo }.count
        if lastWeekFeedings > 0 {
            let change = Double(thisWeekFeedings - lastWeekFeedings) / Double(lastWeekFeedings) * 100
            if change <= -30 {
                alerts.append(TrendAlert(
                    emoji: "⚠️",
                    title: "Beslenme Düşüşü",
                    message: "Bu hafta \(thisWeekFeedings) öğün kaydedildi — geçen hafta \(lastWeekFeedings) öğün. %\(Int(abs(change))) düşüş.",
                    severity: .warning
                ))
            }
        }
        
        // 2. Activity decline (dogs)
        if pet.species == .dog {
            let thisWeekWalkMin = pet.activityLogs.filter { $0.date >= sevenDaysAgo && $0.activityType == .walk }.reduce(0) { $0 + $1.durationMinutes }
            let lastWeekWalkMin = pet.activityLogs.filter { $0.date >= fourteenDaysAgo && $0.date < sevenDaysAgo && $0.activityType == .walk }.reduce(0) { $0 + $1.durationMinutes }
            if lastWeekWalkMin > 0 {
                let change = Double(thisWeekWalkMin - lastWeekWalkMin) / Double(lastWeekWalkMin) * 100
                if change <= -40 {
                    alerts.append(TrendAlert(
                        emoji: "🚶",
                        title: "Yürüyüş Azaldı",
                        message: "Bu hafta \(thisWeekWalkMin) dk yürüyüş — geçen hafta \(lastWeekWalkMin) dk. Daha fazla hareket lazım!",
                        severity: .warning
                    ))
                }
            }
        }
        
        // 3. Increasing symptoms
        let thisWeekSymptoms = pet.behaviorLogs.filter { $0.date >= sevenDaysAgo && $0.severity >= 3 }.count
        let lastWeekSymptoms = pet.behaviorLogs.filter { $0.date >= fourteenDaysAgo && $0.date < sevenDaysAgo && $0.severity >= 3 }.count
        if thisWeekSymptoms > lastWeekSymptoms && thisWeekSymptoms >= 3 {
            alerts.append(TrendAlert(
                emoji: "🚨",
                title: "Semptomlar Artıyor",
                message: "Bu hafta \(thisWeekSymptoms) yüksek şiddetli kayıt — geçen hafta \(lastWeekSymptoms). Veteriner kontrolü düşünün.",
                severity: .critical
            ))
        }
        
        // 4. Weight change detection
        let recentWeights = pet.weightLogs.sorted { $0.date > $1.date }
        if recentWeights.count >= 2 {
            let latest = recentWeights[0].weightKg
            let previous = recentWeights[1].weightKg
            guard previous > 0 else { return alerts }
            let changePercent = ((latest - previous) / previous) * 100
            if abs(changePercent) >= 10 {
                let direction = changePercent > 0 ? "arttı" : "azaldı"
                alerts.append(TrendAlert(
                    emoji: changePercent > 0 ? "📈" : "📉",
                    title: "Kilo Değişimi",
                    message: "\(pet.name)'ın kilosu %\(Int(abs(changePercent))) \(direction): \(String(format: "%.1f", previous)) → \(String(format: "%.1f", latest)) kg",
                    severity: abs(changePercent) >= 20 ? .critical : .warning
                ))
            }
        }
        
        // 5. No records this week
        if thisWeekFeedings == 0 && !pet.feedingLogs.isEmpty {
            alerts.append(TrendAlert(
                emoji: "📝",
                title: "Kayıt Eksik",
                message: "Bu hafta hiç beslenme kaydı girilmemiş. Düzenli kayıt takip için önemli!",
                severity: .info
            ))
        }
        
        return alerts.sorted { $0.severity.rawValue > $1.severity.rawValue }
    }
    
    /// Monthly comparison data for the trend view.
    static func monthlyComparison(for pet: Pet) -> [TrendComparison] {
        let calendar = Calendar.current
        let now = Date()
        let thisMonthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) ?? now
        let lastMonthStart = calendar.date(byAdding: .month, value: -1, to: thisMonthStart) ?? now
        
        var trends: [TrendComparison] = []
        
        // Spending
        let thisMonthSpending = pet.expenses.filter { $0.date >= thisMonthStart }.reduce(0.0) { $0 + $1.amount }
        let lastMonthSpending = pet.expenses.filter { $0.date >= lastMonthStart && $0.date < thisMonthStart }.reduce(0.0) { $0 + $1.amount }
        trends.append(TrendComparison(
            label: "Harcama", icon: "turkishlirasign.circle.fill",
            currentValue: thisMonthSpending, previousValue: lastMonthSpending,
            unit: "₺", isHigherBetter: nil
        ))
        
        // Vet visits
        let thisMonthVets = Double(pet.vetVisits.filter { $0.date >= thisMonthStart }.count)
        let lastMonthVets = Double(pet.vetVisits.filter { $0.date >= lastMonthStart && $0.date < thisMonthStart }.count)
        trends.append(TrendComparison(
            label: "Vet Ziyareti", icon: "cross.case.fill",
            currentValue: thisMonthVets, previousValue: lastMonthVets,
            unit: "ziyaret", isHigherBetter: nil
        ))
        
        // Activity total
        let thisMonthActivities = Double(pet.activityLogs.filter { $0.date >= thisMonthStart }.count)
        let lastMonthActivities = Double(pet.activityLogs.filter { $0.date >= lastMonthStart && $0.date < thisMonthStart }.count)
        trends.append(TrendComparison(
            label: "Aktivite", icon: "flame.fill",
            currentValue: thisMonthActivities, previousValue: lastMonthActivities,
            unit: "kayıt", isHigherBetter: true
        ))
        
        // Feeding
        let thisMonthFeedings = Double(pet.feedingLogs.filter { $0.date >= thisMonthStart }.count)
        let lastMonthFeedings = Double(pet.feedingLogs.filter { $0.date >= lastMonthStart && $0.date < thisMonthStart }.count)
        trends.append(TrendComparison(
            label: "Beslenme", icon: "fork.knife",
            currentValue: thisMonthFeedings, previousValue: lastMonthFeedings,
            unit: "öğün", isHigherBetter: nil
        ))
        
        return trends
    }
}
