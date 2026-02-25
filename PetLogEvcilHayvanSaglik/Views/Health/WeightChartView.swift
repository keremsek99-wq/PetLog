import SwiftUI
import Charts

enum WeightTimeFilter: String, CaseIterable {
    case oneMonth = "1A"
    case threeMonths = "3A"
    case sixMonths = "6A"
    case oneYear = "1Y"
    case all = "Tümü"

    var startDate: Date? {
        switch self {
        case .oneMonth: return Calendar.current.date(byAdding: .month, value: -1, to: Date())
        case .threeMonths: return Calendar.current.date(byAdding: .month, value: -3, to: Date())
        case .sixMonths: return Calendar.current.date(byAdding: .month, value: -6, to: Date())
        case .oneYear: return Calendar.current.date(byAdding: .year, value: -1, to: Date())
        case .all: return nil
        }
    }
}

struct WeightChartView: View {
    let weightLogs: [WeightLog]

    @State private var selectedLog: WeightLog?
    @State private var timeFilter: WeightTimeFilter = .all

    private var filteredLogs: [WeightLog] {
        guard let start = timeFilter.startDate else { return weightLogs }
        return weightLogs.filter { $0.date >= start }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if weightLogs.count >= 2 {
                VStack(spacing: 12) {
                    // Header with selection info
                    HStack {
                        if let selected = selectedLog {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(format: "%.1f kg", selected.weightKg))
                                    .font(.system(.title2, design: .rounded, weight: .bold))
                                    .foregroundStyle(.green)
                                Text(selected.date.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                        } else {
                            VStack(alignment: .leading, spacing: 2) {
                                let current = filteredLogs.last
                                Text(current.map { String(format: "%.1f kg", $0.weightKg) } ?? "--")
                                    .font(.system(.title2, design: .rounded, weight: .bold))
                                Text("Son kilo")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        trendBadge
                    }

                    // Time filter
                    HStack(spacing: 0) {
                        ForEach(WeightTimeFilter.allCases, id: \.self) { filter in
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    timeFilter = filter
                                    selectedLog = nil
                                }
                            } label: {
                                Text(filter.rawValue)
                                    .font(.caption2.weight(.semibold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(
                                        timeFilter == filter
                                            ? Color.green.opacity(0.15)
                                            : Color.clear
                                    )
                                    .foregroundStyle(
                                        timeFilter == filter ? .green : .secondary
                                    )
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            .sensoryFeedback(.selection, trigger: timeFilter)
                        }
                    }

                    // Chart
                    if filteredLogs.count >= 2 {
                        Chart(filteredLogs, id: \.id) { log in
                            LineMark(
                                x: .value("Tarih", log.date),
                                y: .value("Kilo", log.weightKg)
                            )
                            .foregroundStyle(.green)
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 2.5))

                            AreaMark(
                                x: .value("Tarih", log.date),
                                y: .value("Kilo", log.weightKg)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.green.opacity(0.25), .green.opacity(0.02)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                            if let selected = selectedLog, selected.id == log.id {
                                PointMark(
                                    x: .value("Tarih", log.date),
                                    y: .value("Kilo", log.weightKg)
                                )
                                .foregroundStyle(.green)
                                .symbolSize(80)

                                RuleMark(x: .value("Tarih", log.date))
                                    .foregroundStyle(.green.opacity(0.3))
                                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))
                            } else {
                                PointMark(
                                    x: .value("Tarih", log.date),
                                    y: .value("Kilo", log.weightKg)
                                )
                                .foregroundStyle(.green)
                                .symbolSize(20)
                            }
                        }
                        .chartYScale(domain: yDomain(for: filteredLogs))
                        .chartXAxis {
                            AxisMarks(values: .automatic(desiredCount: 4)) {
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) {
                                AxisValueLabel()
                                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.3))
                            }
                        }
                        .chartOverlay { proxy in
                            GeometryReader { geometry in
                                Rectangle()
                                    .fill(.clear)
                                    .contentShape(Rectangle())
                                    .gesture(
                                        DragGesture(minimumDistance: 0)
                                            .onChanged { value in
                                                let origin = geometry[proxy.plotFrame!].origin
                                                let location = CGPoint(
                                                    x: value.location.x - origin.x,
                                                    y: value.location.y - origin.y
                                                )
                                                if let date: Date = proxy.value(atX: location.x) {
                                                    selectedLog = closestLog(to: date, in: filteredLogs)
                                                }
                                            }
                                            .onEnded { _ in
                                                selectedLog = nil
                                            }
                                    )
                            }
                        }
                        .frame(height: 220)
                        .clipped()
                        .animation(.easeInOut(duration: 0.3), value: selectedLog?.id)
                    } else {
                        Text("Bu dönem için yeterli veri yok")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 32)
                    }

                    // Min/Max stats
                    if filteredLogs.count >= 2 {
                        HStack(spacing: 16) {
                            statItem(label: "Min", value: filteredLogs.map(\.weightKg).min() ?? 0, color: .blue)
                            statItem(label: "Ort", value: filteredLogs.map(\.weightKg).reduce(0, +) / Double(filteredLogs.count), color: .green)
                            statItem(label: "Max", value: filteredLogs.map(\.weightKg).max() ?? 0, color: .orange)
                        }
                    }
                }
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

    // MARK: - Trend Badge

    @ViewBuilder
    private var trendBadge: some View {
        let logs = filteredLogs
        if logs.count >= 2 {
            let last = logs[logs.count - 1].weightKg
            let prev = logs[logs.count - 2].weightKg
            let diff = last - prev
            let arrow = diff > 0 ? "arrow.up.right" : (diff < 0 ? "arrow.down.right" : "arrow.right")
            let color: Color = abs(diff) < 0.1 ? .secondary : (diff > 0 ? .orange : .blue)

            HStack(spacing: 4) {
                Image(systemName: arrow)
                    .font(.caption2.weight(.bold))
                Text(String(format: "%+.1f kg", diff))
                    .font(.caption.weight(.semibold).monospacedDigit())
            }
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
        }
    }

    // MARK: - Stat Item

    private func statItem(label: String, value: Double, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
            Text(String(format: "%.1f", value))
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(color)
            Text("kg")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.06))
        .clipShape(.rect(cornerRadius: 8))
    }

    // MARK: - Helpers

    private func yDomain(for logs: [WeightLog]) -> ClosedRange<Double> {
        let weights = logs.map(\.weightKg)
        let minW = (weights.min() ?? 0) * 0.95
        let maxW = (weights.max() ?? 10) * 1.05
        return minW...maxW
    }

    private func closestLog(to date: Date, in logs: [WeightLog]) -> WeightLog? {
        logs.min(by: { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) })
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
