import SwiftUI

// MARK: - Color Palette (Warm & Playful)

enum PetOSColors {
    // Primary accents
    static let accent = Color(hue: 0.58, saturation: 0.65, brightness: 0.95)
    static let healthGreen = Color(hue: 0.38, saturation: 0.55, brightness: 0.85)
    static let financeOrange = Color(hue: 0.08, saturation: 0.70, brightness: 0.95)
    static let warningYellow = Color(hue: 0.12, saturation: 0.65, brightness: 0.95)
    static let urgentRed = Color(hue: 0.0, saturation: 0.60, brightness: 0.90)
    static let insightPurple = Color(hue: 0.78, saturation: 0.45, brightness: 0.85)

    // Warm background tints
    static let warmBackground = Color(hue: 0.08, saturation: 0.04, brightness: 0.97)
    static let cardGlow = Color(hue: 0.58, saturation: 0.15, brightness: 0.98)

    // Species accent colors
    static func speciesColor(_ species: PetSpecies) -> Color {
        switch species {
        case .dog: return Color(hue: 0.08, saturation: 0.55, brightness: 0.92)     // warm amber
        case .cat: return Color(hue: 0.78, saturation: 0.40, brightness: 0.88)     // soft purple
        case .bird: return Color(hue: 0.55, saturation: 0.50, brightness: 0.90)    // sky blue
        case .rabbit: return Color(hue: 0.85, saturation: 0.35, brightness: 0.90)  // soft pink
        case .fish: return Color(hue: 0.50, saturation: 0.55, brightness: 0.85)    // teal
        case .reptile: return Color(hue: 0.35, saturation: 0.45, brightness: 0.80) // olive green
        case .unspecified, .other: return Color(hue: 0.58, saturation: 0.40, brightness: 0.88)
        }
    }

    // Gradient pairs for species
    static func speciesGradient(_ species: PetSpecies) -> [Color] {
        let base = speciesColor(species)
        return [base, base.opacity(0.6)]
    }

    static func categoryColor(_ category: ExpenseCategory) -> Color {
        switch category {
        case .food: return Color(hue: 0.08, saturation: 0.65, brightness: 0.92)
        case .veterinary: return Color(hue: 0.0, saturation: 0.55, brightness: 0.88)
        case .medication: return Color(hue: 0.58, saturation: 0.55, brightness: 0.90)
        case .grooming: return Color(hue: 0.92, saturation: 0.45, brightness: 0.90)
        case .supplies: return Color(hue: 0.78, saturation: 0.45, brightness: 0.85)
        case .insurance: return Color(hue: 0.38, saturation: 0.50, brightness: 0.85)
        case .training: return Color(hue: 0.14, saturation: 0.60, brightness: 0.92)
        case .boarding: return Color(hue: 0.50, saturation: 0.45, brightness: 0.85)
        case .other: return Color(hue: 0.0, saturation: 0.0, brightness: 0.60)
        }
    }

    static func severityColor(_ severity: InsightSeverity) -> Color {
        switch severity {
        case .info: return accent
        case .warning: return financeOrange
        case .urgent: return urgentRed
        }
    }
}

// MARK: - GlowCard (Replaces SummaryCard with warmth)

struct GlowCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    var isUrgent: Bool = false
    var emoji: String? = nil
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    if let emoji {
                        Text(emoji)
                            .font(.subheadline)
                    } else {
                        Image(systemName: icon)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(iconColor)
                    }
                }
                Text(title)
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                if isUrgent {
                    PulsingDot(color: .red)
                }
            }
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
                .shadow(color: isUrgent ? Color.red.opacity(0.08) : Color.black.opacity(0.04), radius: isUrgent ? 8 : 4, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isUrgent ? Color.red.opacity(0.2) : Color.clear, lineWidth: 1)
        )
    }
}

// Keep SummaryCard as alias for backward compatibility
struct SummaryCard<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: () -> Content

    var body: some View {
        GlowCard(title: title, icon: icon, iconColor: iconColor, content: content)
    }
}

// MARK: - Pulsing Dot (Active Indicators)

struct PulsingDot: View {
    let color: Color
    @State private var isPulsing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.3))
                .frame(width: 12, height: 12)
                .scaleEffect(isPulsing ? 1.6 : 1.0)
                .opacity(isPulsing ? 0 : 0.6)
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: false)) {
                isPulsing = true
            }
        }
    }
}

// MARK: - Animated Counter

struct AnimatedCounter: View {
    let value: Int
    let font: Font
    var color: Color = .primary

    @State private var displayedValue: Int = 0

    var body: some View {
        Text("\(displayedValue)")
            .font(font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
            .onAppear {
                withAnimation(.spring(duration: 0.6, bounce: 0.3)) {
                    displayedValue = value
                }
            }
            .onChange(of: value) { _, newVal in
                withAnimation(.spring(duration: 0.4, bounce: 0.2)) {
                    displayedValue = newVal
                }
            }
    }
}

// MARK: - Feature Hint Bubble

struct FeatureHintBubble: View {
    let message: String
    let icon: String
    @Binding var isVisible: Bool

    var body: some View {
        if isVisible {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundStyle(.blue)
                Text(message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                Spacer()
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        isVisible = false
                    }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.12), lineWidth: 1)
                    )
            )
            .transition(.asymmetric(
                insertion: .move(edge: .top).combined(with: .opacity),
                removal: .opacity
            ))
        }
    }
}

// MARK: - Weekly Summary Banner

struct WeeklySummaryBanner: View {
    let items: [(emoji: String, label: String, value: String)]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(items.indices, id: \.self) { i in
                    HStack(spacing: 6) {
                        Text(items[i].emoji)
                            .font(.caption)
                        VStack(alignment: .leading, spacing: 1) {
                            Text(items[i].value)
                                .font(.caption.weight(.bold))
                            Text(items[i].label)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    if i < items.count - 1 {
                        Divider()
                            .frame(height: 24)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
}

// MARK: - Contextual Alert Banner

struct ContextualAlertBanner: View {
    let emoji: String
    let message: String
    let accentColor: Color
    var actionLabel: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Text(emoji)
                .font(.title3)
            Text(message)
                .font(.subheadline.weight(.medium))
                .fixedSize(horizontal: false, vertical: true)
            Spacer()
            if let actionLabel, let action {
                Button(action: action) {
                    Text(actionLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(accentColor, in: Capsule())
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(accentColor.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(accentColor.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Health Quick Stat Card (for HealthView grid)

struct HealthStatCard: View {
    let title: String
    let emoji: String
    let value: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji)
                    .font(.title2)
                Text(value)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(isSelected ? .white : .primary)
                    .lineLimit(1)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(isSelected ? .white.opacity(0.8) : .secondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(isSelected ? Color.blue : Color(.secondarySystemGroupedBackground))
                    .shadow(color: isSelected ? Color.blue.opacity(0.2) : .clear, radius: 6, y: 2)
            )
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

// MARK: - Original Components (Enhanced)

struct QuickActionButton: View {
    let title: String
    let icon: String
    let color: Color
    var emoji: String? = nil
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.18), color.opacity(0.08)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    if let emoji {
                        Text(emoji)
                            .font(.title2)
                    } else {
                        Image(systemName: icon)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(color)
                    }
                }
                .scaleEffect(isPressed ? 0.9 : 1.0)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.primary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.impact(flexibility: .soft), trigger: isPressed)
        .onLongPressGesture(minimumDuration: 0, pressing: { pressing in
            withAnimation(.spring(duration: 0.2)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct SavedToast: View {
    let message: String
    var emoji: String = "✅"

    var body: some View {
        HStack(spacing: 8) {
            Text(emoji)
                .font(.body)
            Text(message)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
        .clipShape(Capsule())
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
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
