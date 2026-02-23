import WidgetKit
import SwiftUI

// MARK: - Timeline Provider

struct PetLogProvider: TimelineProvider {
    func placeholder(in context: Context) -> PetLogEntry {
        PetLogEntry(date: Date(), data: .placeholder)
    }

    func getSnapshot(in context: Context, completion: @escaping (PetLogEntry) -> Void) {
        let data = WidgetDataService.readWidgetData()
        completion(PetLogEntry(date: Date(), data: data))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PetLogEntry>) -> Void) {
        let data = WidgetDataService.readWidgetData()
        let entry = PetLogEntry(date: Date(), data: data)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 2, to: Date())!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Entry

struct PetLogEntry: TimelineEntry {
    let date: Date
    let data: WidgetDataService.WidgetData
}

// MARK: - Vaccine Widget View

struct VaccineWidgetView: View {
    var entry: PetLogEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "syringe.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.purple)
                Text("Sonraki Asi")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            if let vaccineName = entry.data.nextVaccineName {
                Text(vaccineName)
                    .font(.headline)
                    .lineLimit(1)

                if let date = entry.data.nextVaccineDate {
                    let daysUntil = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
                    HStack(spacing: 4) {
                        Text("\(daysUntil)")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(daysUntil <= 7 ? .orange : .primary)
                        Text("gun")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    if family != .systemSmall {
                        Text(date.formatted(date: .abbreviated, time: .omitted))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Yaklasan asi yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Image(systemName: "checkmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.green)
            }

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Image(systemName: entry.data.petSpeciesIcon)
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text(entry.data.petName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

// MARK: - Food Widget View

struct FoodWidgetView: View {
    var entry: PetLogEntry
    @Environment(\.widgetFamily) var family

    private var daysColor: Color {
        let days = entry.data.foodDaysRemaining
        if days <= 3 { return .red }
        if days <= 7 { return .orange }
        return .green
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: "takeoutbag.and.cup.and.straw.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.orange)
                Text("Mama Stoku")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            if entry.data.foodDaysRemaining >= 0, let brand = entry.data.foodBrand {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(entry.data.foodDaysRemaining)")
                        .font(.system(.title, design: .rounded, weight: .bold))
                        .foregroundStyle(daysColor)
                    Text("gun")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Text(brand)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if family != .systemSmall {
                    ProgressView(value: Double(entry.data.foodDaysRemaining) / 30.0)
                        .tint(daysColor)
                }
            } else {
                Text("Mama takibi yok")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            HStack(spacing: 4) {
                Image(systemName: entry.data.petSpeciesIcon)
                    .font(.caption2)
                    .foregroundStyle(.blue)
                Text(entry.data.petName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

// MARK: - Widget Definitions

struct VaccineWidget: Widget {
    let kind = "VaccineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetLogProvider()) { entry in
            VaccineWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Sonraki Asi")
        .description("Evcil hayvaninizin bir sonraki asi tarihini gorun.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FoodWidget: Widget {
    let kind = "FoodWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PetLogProvider()) { entry in
            FoodWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Mama Stoku")
        .description("Mama ne zaman bitecegini takip edin.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Widget Bundle

@main
struct PetLogWidgetBundle: WidgetBundle {
    var body: some Widget {
        VaccineWidget()
        FoodWidget()
    }
}

// MARK: - Previews

#Preview("Vaccine Widget", as: .systemSmall) {
    VaccineWidget()
} timeline: {
    PetLogEntry(date: .now, data: .placeholder)
}

#Preview("Food Widget", as: .systemSmall) {
    FoodWidget()
} timeline: {
    PetLogEntry(date: .now, data: .placeholder)
}
