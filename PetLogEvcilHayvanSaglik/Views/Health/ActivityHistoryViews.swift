import SwiftUI

struct ActivityLogRow: View {
    let log: ActivityLog
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(activityColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: log.activityType.icon)
                        .font(.subheadline)
                        .foregroundStyle(activityColor)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(log.activityType.rawValue)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(log.date.formatted(date: .abbreviated, time: .shortened))
                    if log.activityType != .potty && log.durationMinutes > 0 {
                        Text("·")
                        Text("\(log.durationMinutes) dk")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if !log.notes.isEmpty {
                Text(log.notes)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .frame(maxWidth: 100, alignment: .trailing)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Sil", systemImage: "trash")
            }
        }
        .contextMenu {
            Button("Sil", role: .destructive, action: onDelete)
        }
    }

    private var activityColor: Color {
        switch log.activityType {
        case .walk: return .cyan
        case .play: return .green
        case .potty: return .brown
        case .grooming: return .pink
        case .bath: return .blue
        case .nailTrim: return .orange
        case .training: return .purple
        case .sleep: return .indigo
        case .other: return .gray
        }
    }
}

struct FeedingLogRow: View {
    let log: FeedingLog
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(mealColor.opacity(0.15))
                .frame(width: 40, height: 40)
                .overlay {
                    Image(systemName: log.mealType.icon)
                        .font(.subheadline)
                        .foregroundStyle(mealColor)
                }
            VStack(alignment: .leading, spacing: 2) {
                Text(log.mealType.rawValue)
                    .font(.headline)
                HStack(spacing: 4) {
                    Text(log.date.formatted(date: .abbreviated, time: .shortened))
                    if log.portionGrams > 0 {
                        Text("·")
                        Text(log.mealType == .water ? "\(Int(log.portionGrams)) ml" : "\(Int(log.portionGrams)) g")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if !log.foodBrand.isEmpty {
                Text(log.foodBrand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color(.tertiarySystemGroupedBackground))
                    .clipShape(Capsule())
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 12))
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: onDelete) {
                Label("Sil", systemImage: "trash")
            }
        }
        .contextMenu {
            Button("Sil", role: .destructive, action: onDelete)
        }
    }

    private var mealColor: Color {
        switch log.mealType {
        case .breakfast: return .orange
        case .lunch: return .yellow
        case .dinner: return .purple
        case .snack: return .green
        case .water: return .blue
        }
    }
}
