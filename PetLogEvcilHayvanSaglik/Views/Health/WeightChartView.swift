import SwiftUI
import Charts

struct WeightChartView: View {
    let weightLogs: [WeightLog]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if weightLogs.count >= 2 {
                Chart(weightLogs, id: \.id) { log in
                    LineMark(
                        x: .value("Tarih", log.date),
                        y: .value("Kilo", log.weightKg)
                    )
                    .foregroundStyle(.green)
                    .interpolationMethod(.catmullRom)

                    AreaMark(
                        x: .value("Tarih", log.date),
                        y: .value("Kilo", log.weightKg)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.green.opacity(0.2), .green.opacity(0.02)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .interpolationMethod(.catmullRom)

                    PointMark(
                        x: .value("Tarih", log.date),
                        y: .value("Kilo", log.weightKg)
                    )
                    .foregroundStyle(.green)
                    .symbolSize(30)
                }
                .chartYScale(domain: yDomain)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) {
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        AxisGridLine()
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) {
                        AxisValueLabel()
                        AxisGridLine()
                    }
                }
                .frame(height: 200)
                .padding(16)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(.rect(cornerRadius: 14))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(chartAccessibilityLabel)
            } else if weightLogs.count == 1 {
                singleWeightView
            }
        }
    }

    private var yDomain: ClosedRange<Double> {
        let weights = weightLogs.map(\.weightKg)
        let minW = (weights.min() ?? 0) * 0.95
        let maxW = (weights.max() ?? 10) * 1.05
        return minW...maxW
    }

    private var singleWeightView: some View {
        SummaryCard(title: "Kilo", icon: "scalemass.fill", iconColor: .green) {
            HStack(alignment: .firstTextBaseline) {
                Text(String(format: "%.1f", weightLogs[0].weightKg))
                    .font(.system(.title, design: .rounded, weight: .bold))
                Text("kg")
                    .font(.body)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(weightLogs[0].date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var chartAccessibilityLabel: String {
        guard let first = weightLogs.first, let last = weightLogs.last else { return "Kilo verisi yok" }
        return "Kilo grafiği, \(first.date.formatted(date: .abbreviated, time: .omitted)) ile \(last.date.formatted(date: .abbreviated, time: .omitted)) arasında, \(String(format: "%.1f", weightLogs.map(\.weightKg).min() ?? 0)) ile \(String(format: "%.1f", weightLogs.map(\.weightKg).max() ?? 0)) kg aralığında"
    }
}
