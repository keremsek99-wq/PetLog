import SwiftUI

/// A chronological timeline of all behavior/symptom logs for a pet.
/// Grouped by day with severity coloring and visual timeline connector.
struct SymptomTimelineView: View {
    let pet: Pet
    
    enum SeverityFilter: Hashable {
        case all
        case low      // 1-2
        case medium   // 3+
        case high     // 4+
    }

    @State private var filterSeverity: SeverityFilter = .all

    private var filteredLogs: [BehaviorLog] {
        let sorted = pet.behaviorLogs.sorted { $0.date > $1.date }
        switch filterSeverity {
        case .all: return sorted
        case .low: return sorted.filter { $0.severity <= 2 }
        case .medium: return sorted.filter { $0.severity >= 3 }
        case .high: return sorted.filter { $0.severity >= 4 }
        }
    }
    
    private var groupedByDay: [(String, [BehaviorLog])] {
        let grouped = Dictionary(grouping: filteredLogs) { log in
            log.date.formatted(date: .abbreviated, time: .omitted)
        }
        return grouped.sorted { a, b in
            guard let aDate = a.value.first?.date, let bDate = b.value.first?.date else { return false }
            return aDate > bDate
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Severity filter
            severityFilter
            
            if filteredLogs.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(groupedByDay, id: \.0) { day, logs in
                            daySection(day: day, logs: logs)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Semptom Çizelgesi")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Severity Filter
    
    private var severityFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(label: "Tümü", isSelected: filterSeverity == .all) {
                    withAnimation { filterSeverity = .all }
                }
                FilterChip(label: "Düşük (1-2)", color: .yellow, isSelected: filterSeverity == .low) {
                    withAnimation { filterSeverity = .low }
                }
                FilterChip(label: "Orta (3+)", color: .orange, isSelected: filterSeverity == .medium) {
                    withAnimation { filterSeverity = .medium }
                }
                FilterChip(label: "Yüksek (4+)", color: .red, isSelected: filterSeverity == .high) {
                    withAnimation { filterSeverity = .high }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    // MARK: - Day Section
    
    private func daySection(day: String, logs: [BehaviorLog]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Day header
            HStack {
                Text(day)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(logs.count) kayıt")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 8)
            
            // Timeline entries
            ForEach(Array(logs.enumerated()), id: \.element.id) { index, log in
                HStack(alignment: .top, spacing: 12) {
                    // Timeline connector
                    VStack(spacing: 0) {
                        Circle()
                            .fill(severityColor(log.severity))
                            .frame(width: 12, height: 12)
                        
                        if index < logs.count - 1 {
                            Rectangle()
                                .fill(Color(.tertiarySystemGroupedBackground))
                                .frame(width: 2)
                                .frame(maxHeight: .infinity)
                        }
                    }
                    .frame(width: 12)
                    
                    // Content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Image(systemName: log.behaviorType.icon)
                                .font(.caption)
                                .foregroundStyle(severityColor(log.severity))
                            Text(log.behaviorType.rawValue)
                                .font(.subheadline.weight(.medium))
                            Spacer()
                            Text(log.date.formatted(.dateTime.hour().minute()))
                                .font(.caption2)
                                .foregroundStyle(.tertiary)
                        }
                        
                        // Severity badge
                        HStack(spacing: 4) {
                            ForEach(1...5, id: \.self) { i in
                                Circle()
                                    .fill(i <= log.severity ? severityColor(log.severity) : Color(.tertiarySystemGroupedBackground))
                                    .frame(width: 6, height: 6)
                            }
                            Text("Şiddet: \(log.severity)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        
                        if !log.notes.isEmpty {
                            Text(log.notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(8)
                                .background(Color(.tertiarySystemGroupedBackground))
                                .clipShape(.rect(cornerRadius: 8))
                        }
                    }
                    .padding(.bottom, 16)
                }
            }
        }
    }
    
    // MARK: - Empty State
    
    private var emptyState: some View {
        VStack(spacing: 12) {
            Text("📋")
                .font(.system(size: 48))
            Text("Semptom Kaydı Yok")
                .font(.headline)
            Text("Davranış ve semptom kayıtlarınız burada kronolojik olarak görünecek.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
    
    private func severityColor(_ severity: Int) -> Color {
        switch severity {
        case 1: return .green
        case 2: return .yellow
        case 3: return .orange
        case 4...5: return .red
        default: return .gray
        }
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let label: String
    var color: Color = .blue
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.medium))
                .foregroundStyle(isSelected ? .white : .primary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(isSelected ? color : Color(.tertiarySystemGroupedBackground))
                )
        }
        .buttonStyle(.plain)
    }
}
