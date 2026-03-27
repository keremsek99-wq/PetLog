import SwiftUI

/// Displays trend comparisons (weekly and monthly) along with
/// trend-based alerts for the selected pet.
struct TrendDashboardView: View {
    let pet: Pet
    let store: PetStore
    
    @State private var selectedPeriod: TrendPeriod = .weekly
    
    enum TrendPeriod: String, CaseIterable {
        case weekly = "Haftalık"
        case monthly = "Aylık"
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Period picker
                Picker("Dönem", selection: $selectedPeriod) {
                    ForEach(TrendPeriod.allCases, id: \.self) { period in
                        Text(period.rawValue).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // Alerts
                alertsSection
                
                // Trend cards
                trendsGrid
            }
            .padding(.vertical)
        }
        .navigationTitle("Trend Analizi")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Alerts Section
    
    @ViewBuilder
    private var alertsSection: some View {
        let alerts = TrendAnalyzer.trendAlerts(for: pet)
        if !alerts.isEmpty {
            VStack(spacing: 8) {
                ForEach(alerts) { alert in
                    HStack(spacing: 10) {
                        Text(alert.emoji)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(alert.title)
                                .font(.subheadline.weight(.semibold))
                            Text(alert.message)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(alert.severity.color.opacity(0.08))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(alert.severity.color.opacity(0.2), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Trends Grid
    
    private var trendsGrid: some View {
        let trends: [TrendComparison] = switch selectedPeriod {
        case .weekly: TrendAnalyzer.weeklyTrends(for: pet)
        case .monthly: TrendAnalyzer.monthlyComparison(for: pet)
        }
        
        return LazyVGrid(columns: [
            GridItem(.flexible(), spacing: 12),
            GridItem(.flexible(), spacing: 12)
        ], spacing: 12) {
            ForEach(Array(trends.enumerated()), id: \.offset) { _, trend in
                TrendCard(trend: trend)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Trend Card

struct TrendCard: View {
    let trend: TrendComparison
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title
            HStack(spacing: 6) {
                Image(systemName: trend.icon)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(trend.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            
            // Current value
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if trend.unit == "₺" {
                    Text(trend.currentValue.formatted(.currency(code: "TRY")))
                        .font(.system(.title3, design: .rounded, weight: .bold))
                } else {
                    Text("\(Int(trend.currentValue))")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                    Text(trend.unit)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Change indicator
            HStack(spacing: 4) {
                Image(systemName: trend.changeDirection.icon)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(trendColor)
                
                if trend.previousValue > 0 {
                    Text("\(trend.changePercent > 0 ? "+" : "")\(Int(trend.changePercent))%")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(trendColor)
                    
                    Text("vs önceki")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                } else {
                    Text("Önceki dönem veri yok")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(trend.isAlarming ? Color.red.opacity(0.3) : Color.clear, lineWidth: 1.5)
        )
    }
    
    private var trendColor: Color {
        guard let isHigherBetter = trend.isHigherBetter else {
            return trend.changeDirection.color
        }
        switch (trend.changeDirection, isHigherBetter) {
        case (.up, true): return .green
        case (.up, false): return .red
        case (.down, true): return .red
        case (.down, false): return .green
        case (.stable, _): return .green
        }
    }
}
