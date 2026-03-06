import SwiftUI

struct NotificationSettingsView: View {
    @AppStorage("morningReminderHour") private var morningHour: Int = 9
    @AppStorage("morningReminderMinute") private var morningMinute: Int = 0
    @AppStorage("eveningReminderHour") private var eveningHour: Int = 21
    @AppStorage("eveningReminderMinute") private var eveningMinute: Int = 0
    @AppStorage("vaccineReminderDaysBefore") private var vaccineDaysBefore: Int = 7
    @AppStorage("weightCheckIntervalDays") private var weightCheckInterval: Int = 14
    @AppStorage("photoReminderEnabled") private var photoReminderEnabled: Bool = true
    @AppStorage("monthlyReportEnabled") private var monthlyReportEnabled: Bool = true
    @AppStorage("dailyTipEnabled") private var dailyTipEnabled: Bool = true

    @State private var morningDate: Date = Date()
    @State private var eveningDate: Date = Date()
    @State private var notificationService = NotificationService.shared
    @State private var saved = false

    var body: some View {
        List {
            // MARK: - Bildirim Durumu
            Section {
                HStack(spacing: 12) {
                    Image(systemName: notificationService.isAuthorized ? "bell.badge.fill" : "bell.slash.fill")
                        .font(.title2)
                        .foregroundStyle(notificationService.isAuthorized ? .green : .red)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(notificationService.isAuthorized ? "Bildirimler Aktif" : "Bildirimler Kapalı")
                            .font(.headline)
                        Text(notificationService.isAuthorized ? "Hatırlatmalar zamanında gelecek" : "Ayarlardan bildirimleri açın")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // MARK: - İlaç Saatleri
            Section {
                HStack {
                    Label("Sabah İlacı", systemImage: "sunrise.fill")
                        .foregroundStyle(.orange)
                    Spacer()
                    DatePicker("", selection: $morningDate, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .onChange(of: morningDate) { _, newVal in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newVal)
                            morningHour = comps.hour ?? 9
                            morningMinute = comps.minute ?? 0
                        }
                }

                HStack {
                    Label("Akşam İlacı", systemImage: "moon.fill")
                        .foregroundStyle(.indigo)
                    Spacer()
                    DatePicker("", selection: $eveningDate, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .onChange(of: eveningDate) { _, newVal in
                            let comps = Calendar.current.dateComponents([.hour, .minute], from: newVal)
                            eveningHour = comps.hour ?? 21
                            eveningMinute = comps.minute ?? 0
                        }
                }
            } header: {
                Text("İlaç Hatırlatma Saatleri")
            } footer: {
                Text("Günde 2 doz ilaçlar için sabah ve akşam saatleri")
            }

            // MARK: - Aşı Hatırlatma
            Section {
                Picker("Aşıdan Önce Hatırlat", selection: $vaccineDaysBefore) {
                    Text("3 gün önce").tag(3)
                    Text("5 gün önce").tag(5)
                    Text("7 gün önce").tag(7)
                    Text("14 gün önce").tag(14)
                    Text("30 gün önce").tag(30)
                }
            } header: {
                Text("Aşı Hatırlatma")
            } footer: {
                Text("Aşı tarihinden kaç gün önce hatırlatılsın")
            }

            // MARK: - Kilo Kontrol Sıklığı
            Section {
                Picker("Kilo Kontrol Hatırlatma", selection: $weightCheckInterval) {
                    Text("Haftalık").tag(7)
                    Text("2 haftada bir").tag(14)
                    Text("Aylık").tag(30)
                    Text("3 ayda bir").tag(90)
                }
            } header: {
                Text("Kilo Takibi")
            }

            // MARK: - Ek Hatırlatmalar
            Section {
                Toggle(isOn: $photoReminderEnabled) {
                    Label("📸 Aylık Fotoğraf Hatırlatıcı", systemImage: "camera.fill")
                }

                Toggle(isOn: $monthlyReportEnabled) {
                    Label("📊 Aylık Harcama Özeti", systemImage: "chart.bar.fill")
                }

                Toggle(isOn: $dailyTipEnabled) {
                    Label("💡 Günlük Bakım İpucu", systemImage: "lightbulb.fill")
                }
            } header: {
                Text("Ek Hatırlatmalar")
            }

            // MARK: - Kaydet
            Section {
                Button {
                    applySettings()
                } label: {
                    HStack {
                        Spacer()
                        Label("Ayarları Uygula", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                        Spacer()
                    }
                }
                .listRowBackground(Color.accentColor)
                .foregroundStyle(.white)
            }
        }
        .navigationTitle("Bildirim Ayarları")
        .navigationBarTitleDisplayMode(.inline)
        .sensoryFeedback(.success, trigger: saved)
        .onAppear {
            setupDatePickers()
            Task {
                await notificationService.checkAuthorization()
            }
        }
    }

    private func setupDatePickers() {
        var morningComps = DateComponents()
        morningComps.hour = morningHour
        morningComps.minute = morningMinute
        morningDate = Calendar.current.date(from: morningComps) ?? Date()

        var eveningComps = DateComponents()
        eveningComps.hour = eveningHour
        eveningComps.minute = eveningMinute
        eveningDate = Calendar.current.date(from: eveningComps) ?? Date()
    }

    private func applySettings() {
        saved = true
        // NotificationService will re-read AppStorage values on next schedule
    }
}
