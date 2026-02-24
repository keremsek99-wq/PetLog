import SwiftUI

enum PetOSColors {
    static let accent = Color.blue
    static let healthGreen = Color.green
    static let financeOrange = Color.orange
    static let warningYellow = Color.yellow
    static let urgentRed = Color.red
    static let insightPurple = Color.purple

    static func categoryColor(_ category: ExpenseCategory) -> Color {
        switch category {
        case .food: return .orange
        case .veterinary: return .red
        case .medication: return .blue
        case .grooming: return .pink
        case .supplies: return .purple
        case .insurance: return .green
        case .training: return .yellow
        case .boarding: return .teal
        case .other: return .gray
        }
    }

    static func severityColor(_ severity: InsightSeverity) -> Color {
        switch severity {
        case .info: return .blue
        case .warning: return .orange
        case .urgent: return .red
        }
    }
}

struct SummaryCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(.rect(cornerRadius: 14))
    }
}

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12))
                    .clipShape(Circle())
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let icon: String
    var iconColor: Color = .blue

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.body.weight(.medium))
                .foregroundStyle(iconColor)
                .frame(width: 28)
            Text(label)
                .font(.body)
            Spacer()
            Text(value)
                .font(.body.weight(.semibold))
                .foregroundStyle(.primary)
        }
    }
}

struct EmptyStateView: View {
    let title: String
    let message: String
    let icon: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: icon)
        } description: {
            Text(message)
        } actions: {
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(.borderedProminent)
            }
        }
    }
}

struct SkeletonView: View {
    var height: CGFloat = 20

    @State private var shimmer = false

    var body: some View {
        RoundedRectangle(cornerRadius: 6)
            .fill(Color(.systemGray5))
            .frame(height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color(.systemGray4).opacity(0.5), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .offset(x: shimmer ? 200 : -200)
            )
            .clipShape(.rect(cornerRadius: 6))
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    shimmer = true
                }
            }
    }
}

struct SectionHeader: View {
    let title: String
    var action: String? = nil
    var onAction: (() -> Void)? = nil

    var body: some View {
        HStack {
            Text(title)
                .font(.title3.weight(.bold))
            Spacer()
            if let action, let onAction {
                Button(action, action: onAction)
                    .font(.subheadline.weight(.medium))
            }
        }
    }
}

struct ProgressRing: View {
    let progress: Double
    let color: Color
    var lineWidth: CGFloat = 6

    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.15), lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: min(progress, 1.0))
                .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
        }
    }
}
