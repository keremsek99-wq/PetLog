import SwiftUI

struct PetCalendarView: View {
    let store: PetStore
    let premiumManager: PremiumManager

    @State private var selectedDate = Date()
    @State private var displayedMonth = Date()

    private var pet: Pet? { store.selectedPet }
    private let calendar = Calendar.current

    // All events for the current pet
    private var allEvents: [CalendarEvent] {
        guard let pet else { return [] }
        var events: [CalendarEvent] = []

        // Vaccine due dates
        for vaccine in pet.vaccineRecords {
            if let dueDate = vaccine.dueDate {
                events.append(CalendarEvent(
                    date: dueDate,
                    title: "💉 \(vaccine.name)",
                    type: .vaccine,
                    color: .blue
                ))
            }
            events.append(CalendarEvent(
                date: vaccine.dateAdministered,
                title: "✅ \(vaccine.name) (yapıldı)",
                type: .vaccine,
                color: .green
            ))
        }

        // Vet visits
        for visit in pet.vetVisits {
            events.append(CalendarEvent(
                date: visit.date,
                title: "🏥 \(visit.reason)",
                type: .vetVisit,
                color: .red
            ))
        }

        // Medication start/end
        for med in pet.medications {
            events.append(CalendarEvent(
                date: med.startDate,
                title: "💊 \(med.name) başladı",
                type: .medication,
                color: .purple
            ))
            if let endDate = med.endDate {
                events.append(CalendarEvent(
                    date: endDate,
                    title: "💊 \(med.name) bitiyor",
                    type: .medication,
                    color: .orange
                ))
            }
        }

        // Weight logs
        for log in pet.weightLogs {
            events.append(CalendarEvent(
                date: log.date,
                title: "⚖️ \(String(format: "%.1f", log.weightKg)) kg",
                type: .weight,
                color: .teal
            ))
        }

        // Photo logs
        for photo in pet.photoLogs {
            events.append(CalendarEvent(
                date: photo.date,
                title: "📸 \(photo.caption.isEmpty ? "Fotoğraf" : photo.caption)",
                type: .photo,
                color: .pink
            ))
        }

        // Milestones
        for milestone in pet.milestones {
            events.append(CalendarEvent(
                date: milestone.date,
                title: "\(milestone.emoji) \(milestone.title)",
                type: .milestone,
                color: .yellow
            ))
        }

        // Vet appointments
        for appt in pet.vetAppointments {
            events.append(CalendarEvent(
                date: appt.date,
                title: "📅 \(appt.title)",
                type: .appointment,
                color: .indigo
            ))
        }

        return events
    }

    private func eventsFor(date: Date) -> [CalendarEvent] {
        allEvents.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }

    private func hasEvents(on date: Date) -> Bool {
        !eventsFor(date: date).isEmpty
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                calendarGrid
                Divider()
                eventsList
            }
            .navigationTitle("Takvim")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    // MARK: - Calendar Grid

    private var calendarGrid: some View {
        VStack(spacing: 8) {
            // Month navigation
            HStack {
                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        displayedMonth = calendar.date(byAdding: .month, value: -1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.headline)
                }

                Spacer()

                let formatter: DateFormatter = {
                    let f = DateFormatter()
                    f.locale = Locale(identifier: "tr_TR")
                    f.dateFormat = "MMMM yyyy"
                    return f
                }()
                Text(formatter.string(from: displayedMonth))
                    .font(.headline)

                Spacer()

                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        displayedMonth = calendar.date(byAdding: .month, value: 1, to: displayedMonth) ?? displayedMonth
                    }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.headline)
                }
            }
            .padding(.horizontal)

            // Day headers
            let daySymbols = ["Pzt", "Sal", "Çar", "Per", "Cum", "Cmt", "Paz"]
            HStack(spacing: 0) {
                ForEach(daySymbols, id: \.self) { day in
                    Text(day)
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar days
            let days = daysInMonth()
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 0), count: 7), spacing: 4) {
                ForEach(days, id: \.self) { date in
                    if let date {
                        dayCell(date)
                    } else {
                        Text("")
                            .frame(height: 36)
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
    }

    private func dayCell(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selectedDate)
        let isToday = calendar.isDateInToday(date)
        let dayEvents = eventsFor(date: date)
        // Show up to 3 distinct event type colors as dots
        let eventColors: [Color] = Array(Set(dayEvents.map { $0.type }).prefix(3)).map { type in
            dayEvents.first { $0.type == type }?.color ?? .blue
        }

        return Button {
            withAnimation(.spring(duration: 0.2)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 2) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.system(isToday ? .callout : .callout, weight: isToday ? .bold : .regular))
                    .foregroundStyle(isSelected ? .white : (isToday ? .blue : .primary))

                if !eventColors.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(Array(eventColors.enumerated()), id: \.offset) { _, color in
                            Circle()
                                .fill(isSelected ? .white : color)
                                .frame(width: 4, height: 4)
                        }
                    }
                } else {
                    Spacer().frame(height: 4)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 36)
            .background(
                isSelected ? Color.blue.clipShape(RoundedRectangle(cornerRadius: 8)) :
                    isToday ? Color.blue.opacity(0.1).clipShape(RoundedRectangle(cornerRadius: 8)) :
                    Color.clear.clipShape(RoundedRectangle(cornerRadius: 8))
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Events List

    private var eventsList: some View {
        let events = eventsFor(date: selectedDate)
        return ScrollView {
            LazyVStack(spacing: 8) {
                if events.isEmpty {
                    VStack(spacing: 8) {
                        Text("📅")
                            .font(.title)
                        Text("Bu tarihte etkinlik yok")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 32)
                } else {
                    let dateStr: String = {
                        let f = DateFormatter()
                        f.locale = Locale(identifier: "tr_TR")
                        f.dateFormat = "d MMMM, EEEE"
                        return f.string(from: selectedDate)
                    }()
                    Text(dateStr)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .padding(.top, 8)

                    ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                        HStack(spacing: 12) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(event.color)
                                .frame(width: 4)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(event.title)
                                    .font(.subheadline.weight(.semibold))
                                Text(event.type.rawValue)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                        }
                        .padding(10)
                        .background(Color(.secondarySystemGroupedBackground))
                        .clipShape(.rect(cornerRadius: 10))
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.bottom, 24)
        }
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - Helpers

    private func daysInMonth() -> [Date?] {
        let components = calendar.dateComponents([.year, .month], from: displayedMonth)
        guard let firstOfMonth = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: firstOfMonth) else {
            return []
        }

        // Calculate offset so Monday=0 (weekday: Sun=1, Mon=2, ..., Sat=7)
        let weekday = (calendar.component(.weekday, from: firstOfMonth) + 5) % 7

        var days: [Date?] = Array(repeating: nil, count: weekday)

        for day in range {
            if let date = calendar.date(bySetting: .day, value: day, of: firstOfMonth) {
                days.append(date)
            }
        }

        // Pad to fill last row
        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }
}

// MARK: - Calendar Event

struct CalendarEvent {
    let date: Date
    let title: String
    let type: EventType
    let color: Color
}

enum EventType: String {
    case vaccine = "Aşı"
    case vetVisit = "Veteriner Ziyareti"
    case medication = "İlaç"
    case weight = "Kilo Kaydı"
    case photo = "Fotoğraf"
    case milestone = "Anı"
    case appointment = "Randevu"
}
