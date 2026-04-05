import SwiftUI
import SwiftData
import EventKit
import os.log

private let logger = Logger(subsystem: "com.petlog.app", category: "VetAppointment")

struct VetAppointmentView: View {
    let store: PetStore
    let premiumManager: PremiumManager

    @State private var showAddSheet = false

    private var pet: Pet? { store.selectedPet }

    private var upcomingAppointments: [VetAppointment] {
        (pet?.vetAppointments ?? []).filter { $0.isUpcoming }.sorted { $0.date < $1.date }
    }

    private var pastAppointments: [VetAppointment] {
        (pet?.vetAppointments ?? []).filter { !$0.isUpcoming }.sorted { $0.date > $1.date }
    }

    var body: some View {
        NavigationStack {
            List {
                if upcomingAppointments.isEmpty && pastAppointments.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("Randevu Yok", systemImage: "calendar.badge.plus")
                        } description: {
                            Text("Veteriner randevusu ekleyin ve takvime kaydedin.")
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                if !upcomingAppointments.isEmpty {
                    Section("Yaklaşan Randevular") {
                        ForEach(upcomingAppointments, id: \.id) { appt in
                            appointmentRow(appt, isUpcoming: true)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                let appt = upcomingAppointments[index]
                                removeCalendarEvent(for: appt)
                                store.modelContext.delete(appt)
                            }
                        }
                    }
                }

                if !pastAppointments.isEmpty {
                    Section("Geçmiş Randevular") {
                        ForEach(pastAppointments.prefix(10), id: \.id) { appt in
                            appointmentRow(appt, isUpcoming: false)
                        }
                    }
                }
            }
            .navigationTitle("Veteriner Randevuları")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddSheet = true } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                }
            }
            .sheet(isPresented: $showAddSheet) {
                AddVetAppointmentSheet(store: store)
            }
        }
    }

    private func appointmentRow(_ appt: VetAppointment, isUpcoming: Bool) -> some View {
        HStack(spacing: 12) {
            VStack(spacing: 2) {
                let dayStr: String = {
                    let f = DateFormatter()
                    f.locale = Locale(identifier: "tr_TR")
                    f.dateFormat = "dd"
                    return f.string(from: appt.date)
                }()
                let monthStr: String = {
                    let f = DateFormatter()
                    f.locale = Locale(identifier: "tr_TR")
                    f.dateFormat = "MMM"
                    return f.string(from: appt.date)
                }()
                Text(dayStr)
                    .font(.title3.weight(.bold))
                Text(monthStr)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 40)
            .padding(6)
            .background(isUpcoming ? Color.indigo.opacity(0.1) : Color(.tertiarySystemGroupedBackground))
            .clipShape(.rect(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(appt.title)
                    .font(.subheadline.weight(.semibold))
                HStack(spacing: 6) {
                    Text(appt.date, style: .time)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if !appt.vetName.isEmpty {
                        Text("· \(appt.vetName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                if !appt.location.isEmpty {
                    Text("📍 \(appt.location)")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()

            if isUpcoming && !appt.vetPhone.isEmpty {
                let sanitizedPhone = appt.vetPhone.filter { $0.isNumber || $0 == "+" }
                if let phoneURL = URL(string: "tel:\(sanitizedPhone)") {
                    Link(destination: phoneURL) {
                        Image(systemName: "phone.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.green)
                    }
                }
            }
        }
    }

    /// Remove the associated calendar event when deleting an appointment
    private func removeCalendarEvent(for appointment: VetAppointment) {
        guard let eventID = appointment.calendarEventID, !eventID.isEmpty else { return }
        let eventStore = EKEventStore()
        if let event = eventStore.event(withIdentifier: eventID) {
            do {
                try eventStore.remove(event, span: .thisEvent)
            } catch {
                logger.warning("Failed to remove calendar event: \(error.localizedDescription)")
            }
        }
    }
}

// MARK: - Add Vet Appointment Sheet

struct AddVetAppointmentSheet: View {
    let store: PetStore
    @Environment(\.dismiss) private var dismiss

    @State private var title = ""
    @State private var date = Date()
    @State private var vetName = ""
    @State private var vetPhone = ""
    @State private var location = ""
    @State private var notes = ""
    @State private var reminderMinutes = 60
    @State private var addToCalendar = true
    @State private var showCalendarError = false
    @State private var calendarErrorMessage = ""

    private let reminderOptions = [
        (0, "Yok"),
        (15, "15 dakika önce"),
        (30, "30 dakika önce"),
        (60, "1 saat önce"),
        (120, "2 saat önce"),
        (1440, "1 gün önce"),
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 12) {
                        Text("🏥")
                            .font(.largeTitle)
                        VStack(alignment: .leading) {
                            Text("Yeni Randevu")
                                .font(.headline)
                            Text("Veteriner randevusu planlayın")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowBackground(Color.clear)
                }

                Section("Randevu Detayları") {
                    TextField("Randevu Başlığı (örn: Aşı kontrolü)", text: $title)
                        .onChange(of: title) { _, v in if v.count > 100 { title = String(v.prefix(100)) } }
                    DatePicker("Tarih ve Saat", selection: $date, in: Date()...)
                    TextField("Notlar", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                        .onChange(of: notes) { _, v in if v.count > 500 { notes = String(v.prefix(500)) } }
                }

                Section("Veteriner Bilgileri") {
                    TextField("Veteriner Adı", text: $vetName)
                        .onChange(of: vetName) { _, v in if v.count > 100 { vetName = String(v.prefix(100)) } }
                    TextField("Telefon", text: $vetPhone)
                        .keyboardType(.phonePad)
                        .onChange(of: vetPhone) { _, v in if v.count > 20 { vetPhone = String(v.prefix(20)) } }
                    TextField("Adres / Konum", text: $location)
                        .onChange(of: location) { _, v in if v.count > 200 { location = String(v.prefix(200)) } }
                }

                Section("Hatırlatma") {
                    Picker("Hatırlatma", selection: $reminderMinutes) {
                        ForEach(reminderOptions, id: \.0) { option in
                            Text(option.1).tag(option.0)
                        }
                    }

                    Toggle(isOn: $addToCalendar) {
                        Label("iOS Takvime Ekle", systemImage: "calendar")
                    }
                }
            }
            .navigationTitle("Randevu Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("İptal") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Kaydet") {
                        saveAppointment()
                    }
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                    .fontWeight(.semibold)
                }
            }
            .alert("Takvim Hatası", isPresented: $showCalendarError) {
                Button("Tamam") {}
            } message: {
                Text(calendarErrorMessage)
            }
        }
    }

    private func saveAppointment() {
        guard let pet = store.selectedPet else { return }

        // Auto-fill vet info from emergency card if available
        let vet = vetName.isEmpty ? pet.emergencyVetName : vetName
        let phone = vetPhone.isEmpty ? pet.emergencyVetPhone : vetPhone

        let appointment = VetAppointment(
            title: title.trimmingCharacters(in: .whitespaces),
            date: date,
            vetName: vet,
            vetPhone: phone,
            location: location,
            notes: notes,
            reminderMinutesBefore: reminderMinutes
        )
        appointment.pet = pet
        store.modelContext.insert(appointment)

        // Add to iOS Calendar via EventKit
        if addToCalendar {
            Task {
                await addToDeviceCalendar(appointment: appointment, petName: pet.name)
            }
        }

        dismiss()
    }

    @MainActor
    private func addToDeviceCalendar(appointment: VetAppointment, petName: String) async {
        let eventStore = EKEventStore()

        do {
            let granted = try await eventStore.requestFullAccessToEvents()
            guard granted else {
                calendarErrorMessage = "Takvim erişimi reddedildi. Ayarlar > PetLog'dan takvim iznini açın."
                showCalendarError = true
                return
            }

            let event = EKEvent(eventStore: eventStore)
            event.title = "🐾 \(petName) — \(appointment.title)"
            event.startDate = appointment.date
            event.endDate = Calendar.current.date(byAdding: .hour, value: 1, to: appointment.date)
            event.location = appointment.location
            event.notes = appointment.notes
            event.calendar = eventStore.defaultCalendarForNewEvents

            // Add alarm
            if appointment.reminderMinutesBefore > 0 {
                let alarm = EKAlarm(relativeOffset: TimeInterval(-appointment.reminderMinutesBefore * 60))
                event.addAlarm(alarm)
            }

            try eventStore.save(event, span: .thisEvent)
            appointment.calendarEventID = event.eventIdentifier
        } catch {
            calendarErrorMessage = "Takvime eklenemedi: \(error.localizedDescription)"
            showCalendarError = true
        }
    }
}
