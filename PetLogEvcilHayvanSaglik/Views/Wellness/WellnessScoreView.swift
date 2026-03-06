import SwiftUI

// MARK: - Wellness Score Card (Dashboard)

struct WellnessScoreCard: View {
    let pet: Pet
    @State private var showDetail = false

    private var result: WellnessScoreEngine.ScoreResult {
        WellnessScoreEngine.calculate(for: pet)
    }

    var body: some View {
        Button {
            showDetail = true
        } label: {
            HStack(spacing: 14) {
                // Circular score indicator
                ZStack {
                    Circle()
                        .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 6)
                        .frame(width: 56, height: 56)

                    Circle()
                        .trim(from: 0, to: Double(result.overall) / 100.0)
                        .stroke(
                            result.grade.color,
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 56, height: 56)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text("\(result.overall)")
                            .font(.system(.title3, design: .rounded, weight: .bold))
                        Text("puan")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text("\(result.grade.emoji) Wellness Score")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text(result.grade.rawValue)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(result.grade.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(result.grade.color.opacity(0.12))
                            .clipShape(Capsule())
                    }

                    Text(result.tip)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    // Mini dimension bars
                    HStack(spacing: 4) {
                        ForEach(result.dimensions, id: \.name) { dim in
                            VStack(spacing: 2) {
                                Text(dim.emoji)
                                    .font(.system(size: 10))
                                GeometryReader { geo in
                                    ZStack(alignment: .leading) {
                                        Capsule()
                                            .fill(Color(.tertiarySystemGroupedBackground))
                                        Capsule()
                                            .fill(colorFor(dim.score))
                                            .frame(width: geo.size.width * Double(dim.score) / 100.0)
                                    }
                                }
                                .frame(height: 4)
                            }
                        }
                    }
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showDetail) {
            WellnessScoreDetailView(pet: pet)
        }
    }

    private func colorFor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}

// MARK: - Wellness Score Detail View

struct WellnessScoreDetailView: View {
    let pet: Pet
    @Environment(\.dismiss) private var dismiss

    private var result: WellnessScoreEngine.ScoreResult {
        WellnessScoreEngine.calculate(for: pet)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Big score ring
                    ZStack {
                        Circle()
                            .stroke(Color(.tertiarySystemGroupedBackground), lineWidth: 12)
                            .frame(width: 140, height: 140)

                        Circle()
                            .trim(from: 0, to: Double(result.overall) / 100.0)
                            .stroke(
                                result.grade.color,
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 140, height: 140)
                            .rotationEffect(.degrees(-90))

                        VStack(spacing: 2) {
                            Text("\(result.overall)")
                                .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            Text(result.grade.rawValue)
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(result.grade.color)
                        }
                    }
                    .padding(.top, 8)

                    // Tip
                    HStack {
                        Image(systemName: "lightbulb.fill")
                            .foregroundStyle(.yellow)
                        Text(result.tip)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 10))

                    // Dimension breakdown
                    VStack(spacing: 12) {
                        ForEach(result.dimensions, id: \.name) { dim in
                            HStack(spacing: 12) {
                                Text(dim.emoji)
                                    .font(.title2)
                                    .frame(width: 36)

                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Text(dim.name)
                                            .font(.subheadline.weight(.semibold))
                                        Spacer()
                                        Text("\(dim.score)/100")
                                            .font(.caption.weight(.bold))
                                            .foregroundStyle(colorFor(dim.score))
                                    }

                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(Color(.tertiarySystemGroupedBackground))
                                            Capsule()
                                                .fill(colorFor(dim.score))
                                                .frame(width: geo.size.width * Double(dim.score) / 100.0)
                                        }
                                    }
                                    .frame(height: 8)

                                    Text(dim.detail)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(12)
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(.rect(cornerRadius: 12))
                        }
                    }

                    // Weights explanation
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Puan Ağırlıkları")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)

                        HStack(spacing: 8) {
                            ForEach(result.dimensions, id: \.name) { dim in
                                VStack(spacing: 2) {
                                    Text(dim.emoji)
                                        .font(.caption2)
                                    Text("%\(Int(dim.weight * 100))")
                                        .font(.system(size: 9, weight: .semibold))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(.rect(cornerRadius: 10))
                }
                .padding()
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("\(pet.name) Wellness")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Tamam") { dismiss() }
                }
            }
        }
    }

    private func colorFor(_ score: Int) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .yellow
        case 40..<60: return .orange
        default: return .red
        }
    }
}
