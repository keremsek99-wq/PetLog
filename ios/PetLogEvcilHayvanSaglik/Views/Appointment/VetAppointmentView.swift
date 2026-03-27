import SwiftUI
import SwiftData
import EventKit

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
                                store.modelContext.delete(upcomingAppointments[index])
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
                Link(destination: URL(string: "tel:\(appt.vetPhone.replacingOccurrences(of: " ", with: ""))")!) {
                    Image(systemName: "phone.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.green)
                }
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
                    DatePicker("Tarih ve Saat", selection: $date, in: Date()...)
                    TextField("Notlar", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                }

                Section("Veteriner Bilgileri") {
                    TextField("Veteriner Adı", text: $vetName)
                    TextField("Telefon", text: $vetPhone)
                        .keyboardType(.phonePad)
                    TextField("Adres / Konum", text: $location)
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
                    .disabled(title.isEmpty)
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
            title: title,
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
            addToDeviceCalendar(appointment: appointment, petName: pet.name)
        }

        dismiss()
    }

    private func addToDeviceCalendar(appointment: VetAppointment, petName: String) {
        let eventStore = EKEventStore()

        eventStore.requestFullAccessToEvents { granted, error in
            guard granted, error == nil else {
                DispatchQueue.main.async {
                    calendarErrorMessage = "Takvim erişimi reddedildi. Ayarlar > PetLog'dan takvim iznini açın."
                    showCalendarError = true
                }
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

            do {
                try eventStore.save(event, span: .thisEvent)
                DispatchQueue.main.async {
                    appointment.calendarEventID = event.eventIdentifier
                }
            } catch {
                DispatchQueue.main.async {
                    calendarErrorMessage = "Takvime eklenemedi: \(error.localizedDescription)"
                    showCalendarError = true
                }
            }
        }
    }
}
