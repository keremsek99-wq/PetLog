import Foundation
import UserNotifications

/// Smart notification engine that sends contextual, personalized notifications
struct SmartNotificationEngine {

    static func scheduleAllSmartNotifications(for pet: Pet) {
        let center = UNUserNotificationCenter.current()
        // Clear existing smart notifications
        center.removePendingNotificationRequests(withIdentifiers:
            pendingIdentifiers(for: pet)
        )

        scheduleVaccineReminders(pet: pet, center: center)
        scheduleMedicationReminders(pet: pet, center: center)
        scheduleWeightCheckReminder(pet: pet, center: center)
        scheduleActivityReminder(pet: pet, center: center)
        scheduleSeasonalAlerts(pet: pet, center: center)
        scheduleBirthdayReminder(pet: pet, center: center)
        scheduleWellnessCheckIn(pet: pet, center: center)
    }

    // MARK: - Vaccine Reminders

    private static func scheduleVaccineReminders(pet: Pet, center: UNUserNotificationCenter) {
        for vaccine in pet.vaccineRecords {
            guard let dueDate = vaccine.dueDate, dueDate > Date() else { continue }

            // 1 week before
            if let weekBefore = Calendar.current.date(byAdding: .day, value: -7, to: dueDate), weekBefore > Date() {
                scheduleNotification(
                    id: "smart_vaccine_7d_\(pet.id)_\(vaccine.name)",
                    title: "💉 Aşı Hatırlatması",
                    body: "\(pet.name)'in \(vaccine.name) aşısına 1 hafta kaldı!",
                    date: weekBefore,
                    center: center
                )
            }

            // 1 day before
            if let dayBefore = Calendar.current.date(byAdding: .day, value: -1, to: dueDate), dayBefore > Date() {
                scheduleNotification(
                    id: "smart_vaccine_1d_\(pet.id)_\(vaccine.name)",
                    title: "💉 Yarın Aşı Günü!",
                    body: "\(pet.name)'in \(vaccine.name) aşısı yarın. Veteriner randevunuzu kontrol edin.",
                    date: dayBefore,
                    center: center
                )
            }

            // Due day
            scheduleNotification(
                id: "smart_vaccine_due_\(pet.id)_\(vaccine.name)",
                title: "💉 Bugün Aşı Günü!",
                body: "\(pet.name)'in \(vaccine.name) aşısı bugün yapılmalı.",
                date: dueDate,
                center: center
            )
        }
    }

    // MARK: - Medication Reminders

    private static func scheduleMedicationReminders(pet: Pet, center: UNUserNotificationCenter) {
        for med in pet.medications where med.isActive {
            guard let endDate = med.endDate, endDate > Date() else { continue }

            // 3 days before end
            if let threeDaysBefore = Calendar.current.date(byAdding: .day, value: -3, to: endDate), threeDaysBefore > Date() {
                scheduleNotification(
                    id: "smart_med_end_\(pet.id)_\(med.name)",
                    title: "💊 İlaç Bitiyor",
                    body: "\(pet.name)'in \(med.name) ilacı 3 gün sonra bitiyor. Refill gerekebilir.",
                    date: threeDaysBefore,
                    center: center
                )
            }
        }
    }

    // MARK: - Weight Check

    private static func scheduleWeightCheckReminder(pet: Pet, center: UNUserNotificationCenter) {
        let lastWeight = pet.weightLogs.sorted { $0.date > $1.date }.first
        let daysSinceWeight: Int
        if let last = lastWeight {
            daysSinceWeight = Calendar.current.dateComponents([.day], from: last.date, to: Date()).day ?? 999
        } else {
            daysSinceWeight = 999
        }

        // Remind every 2 weeks if no recent weight
        if daysSinceWeight >= 14 {
            let nextWeekend = Calendar.current.nextDate(
                after: Date(), matching: DateComponents(hour: 10, weekday: 7),
                matchingPolicy: .nextTime
            ) ?? Date().addingTimeInterval(86400)

            scheduleNotification(
                id: "smart_weight_\(pet.id)",
                title: "⚖️ Kilo Kontrolü",
                body: "\(pet.name)'i son tartmanız \(daysSinceWeight) gün önceydi. Kilo kaydı ekleyelim mi?",
                date: nextWeekend,
                center: center
            )
        }
    }

    // MARK: - Activity Reminder

    private static func scheduleActivityReminder(pet: Pet, center: UNUserNotificationCenter) {
        guard pet.species == .dog else { return }

        let today = Calendar.current.startOfDay(for: Date())
        let todayActivities = pet.activityLogs.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }

        if todayActivities.isEmpty {
            // Remind at 5 PM if no walks logged today
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day], from: Date())
            dateComponents.hour = 17
            dateComponents.minute = 0

            if let reminderDate = Calendar.current.date(from: dateComponents), reminderDate > Date() {
                scheduleNotification(
                    id: "smart_activity_\(pet.id)_\(today.timeIntervalSince1970)",
                    title: "🐕 Yürüyüş Zamanı!",
                    body: "\(pet.name) bugün henüz yürüyüşe çıkmadı. Hadi birlikte yürüyelim!",
                    date: reminderDate,
                    center: center
                )
            }
        }
    }

    // MARK: - Seasonal Alerts

    private static func scheduleSeasonalAlerts(pet: Pet, center: UNUserNotificationCenter) {
        let month = Calendar.current.component(.month, from: Date())

        // Spring - parasite season
        if month == 3 || month == 4 {
            scheduleNotification(
                id: "smart_seasonal_spring_\(pet.id)_\(month)",
                title: "🌸 Bahar Parazit Sezonu",
                body: "\(pet.name) için iç ve dış parazit korumasını kontrol edin. Kene ve pire sezonu başlıyor!",
                date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                center: center
            )
        }

        // Summer - heat
        if month == 6 || month == 7 || month == 8 {
            scheduleNotification(
                id: "smart_seasonal_summer_\(pet.id)_\(month)",
                title: "☀️ Sıcak Hava Uyarısı",
                body: "\(pet.name) için bol su ve gölge unutmayın. Asfalt üzerinde yürümeyi sınırlandırın.",
                date: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date(),
                center: center
            )
        }
    }

    // MARK: - Birthday

    private static func scheduleBirthdayReminder(pet: Pet, center: UNUserNotificationCenter) {
        let calendar = Calendar.current
        let now = Date()
        let currentYear = calendar.component(.year, from: now)

        var birthdayComponents = calendar.dateComponents([.month, .day], from: pet.birthdate)
        birthdayComponents.year = currentYear
        birthdayComponents.hour = 9

        if let birthday = calendar.date(from: birthdayComponents) {
            let targetBirthday = birthday > now ? birthday : calendar.date(byAdding: .year, value: 1, to: birthday) ?? birthday

            scheduleNotification(
                id: "smart_birthday_\(pet.id)",
                title: "🎂 Doğum Günü!",
                body: "Bugün \(pet.name)'in doğum günü! Mutlu yıllar 🎉🐾",
                date: targetBirthday,
                center: center
            )

            // 1 week before
            if let weekBefore = calendar.date(byAdding: .day, value: -7, to: targetBirthday), weekBefore > now {
                scheduleNotification(
                    id: "smart_birthday_7d_\(pet.id)",
                    title: "🎁 Doğum Günü Yaklaşıyor",
                    body: "\(pet.name)'in doğum gününe 1 hafta kaldı! Sürprizler için hazırlanın.",
                    date: weekBefore,
                    center: center
                )
            }
        }
    }

    // MARK: - Weekly Wellness Check-in

    private static func scheduleWellnessCheckIn(pet: Pet, center: UNUserNotificationCenter) {
        // Every Sunday at 10 AM
        var dateComponents = DateComponents()
        dateComponents.weekday = 1  // Sunday
        dateComponents.hour = 10

        let content = UNMutableNotificationContent()
        content.title = "📊 Haftalık Sağlık Özeti"
        let score = WellnessScoreEngine.calculate(for: pet)
        content.body = "\(pet.name) Wellness Skoru: \(score.overall)/100 (\(score.grade.rawValue)). Detaylar için uygulama açın."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: "smart_wellness_weekly_\(pet.id)",
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    // MARK: - Helpers

    private static func scheduleNotification(id: String, title: String, body: String, date: Date, center: UNUserNotificationCenter) {
        guard date > Date() else { return }

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)

        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        center.add(request)
    }

    private static func pendingIdentifiers(for pet: Pet) -> [String] {
        // Build list of known smart notification IDs
        var ids: [String] = []
        ids.append("smart_weight_\(pet.id)")
        ids.append("smart_birthday_\(pet.id)")
        ids.append("smart_birthday_7d_\(pet.id)")
        ids.append("smart_wellness_weekly_\(pet.id)")
        for v in pet.vaccineRecords {
            ids.append("smart_vaccine_7d_\(pet.id)_\(v.name)")
            ids.append("smart_vaccine_1d_\(pet.id)_\(v.name)")
            ids.append("smart_vaccine_due_\(pet.id)_\(v.name)")
        }
        for m in pet.medications {
            ids.append("smart_med_end_\(pet.id)_\(m.name)")
        }
        return ids
    }
}
