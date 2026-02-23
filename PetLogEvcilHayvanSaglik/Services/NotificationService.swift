import Foundation
import UserNotifications

@Observable
@MainActor
class NotificationService {
    static let shared = NotificationService()

    var isAuthorized: Bool = false
    var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() {}

    func checkAuthorization() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
        isAuthorized = settings.authorizationStatus == .authorized
    }

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            isAuthorized = granted
            if granted {
                authorizationStatus = .authorized
            }
            return granted
        } catch {
            return false
        }
    }

    func scheduleAllReminders(for pets: [Pet]) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let isPremium = PremiumManager.shared.hasFullAccess

        for pet in pets {
            // Free: aşı + ilaç hatırlatmaları
            scheduleVaccineReminders(for: pet)
            scheduleMedicationReminders(for: pet)

            // Premium: mama bitiş, kilo kontrol
            if isPremium {
                scheduleFoodRunoutReminder(for: pet)
                scheduleWeightCheckReminder(for: pet)
            }
        }

        // Premium: aylık harcama özeti
        if isPremium {
            scheduleMonthlySpendingSummary()
        }
    }

    private func scheduleVaccineReminders(for pet: Pet) {
        for vaccine in pet.vaccineRecords {
            guard let dueDate = vaccine.dueDate, dueDate > Date() else { continue }

            let sevenDaysBefore = Calendar.current.date(byAdding: .day, value: -7, to: dueDate)
            if let reminderDate = sevenDaysBefore, reminderDate > Date() {
                scheduleNotification(
                    id: "vaccine-7d-\(vaccine.id.uuidString)",
                    title: "Aşı Hatırlatma",
                    body: "\(pet.name)'in \(vaccine.name) aşısına 7 gün kaldı.",
                    date: reminderDate
                )
            }

            let oneDayBefore = Calendar.current.date(byAdding: .day, value: -1, to: dueDate)
            if let reminderDate = oneDayBefore, reminderDate > Date() {
                scheduleNotification(
                    id: "vaccine-1d-\(vaccine.id.uuidString)",
                    title: "Aşı Yarın!",
                    body: "\(pet.name)'in \(vaccine.name) aşısı yarın yapılmalı.",
                    date: reminderDate
                )
            }

            scheduleNotification(
                id: "vaccine-due-\(vaccine.id.uuidString)",
                title: "Aşı Günü",
                body: "\(pet.name)'in \(vaccine.name) aşı günü bugün.",
                date: dueDate
            )
        }
    }

    private func scheduleMedicationReminders(for pet: Pet) {
        for med in pet.activeMedications {
            let id = "med-\(med.id.uuidString)"

            switch med.schedule {
            case .daily, .twiceDaily:
                var morning = DateComponents()
                morning.hour = 9
                morning.minute = 0
                scheduleRepeating(
                    id: id,
                    title: "İlaç Hatırlatma",
                    body: "\(pet.name) - \(med.name) \(med.dosage)",
                    dateComponents: morning
                )
                if med.schedule == .twiceDaily {
                    var evening = DateComponents()
                    evening.hour = 21
                    evening.minute = 0
                    scheduleRepeating(
                        id: "\(id)-pm",
                        title: "Akşam İlaç Hatırlatma",
                        body: "\(pet.name) - \(med.name) akşam dozu",
                        dateComponents: evening
                    )
                }
            case .weekly:
                var weekly = DateComponents()
                weekly.weekday = 2
                weekly.hour = 9
                scheduleRepeating(
                    id: id,
                    title: "Haftalık İlaç",
                    body: "\(pet.name) - \(med.name) verme zamanı.",
                    dateComponents: weekly
                )
            case .monthly:
                var monthly = DateComponents()
                monthly.day = Calendar.current.component(.day, from: med.startDate)
                monthly.hour = 9
                scheduleRepeating(
                    id: id,
                    title: "Aylık İlaç",
                    body: "\(pet.name) - \(med.name) verme zamanı.",
                    dateComponents: monthly
                )
            case .asNeeded:
                break
            }
        }
    }

    private func scheduleFoodRunoutReminder(for pet: Pet) {
        guard let food = pet.currentFood else { return }
        let daysLeft = food.daysUntilRunout
        guard daysLeft > 0, daysLeft <= 7 else { return }

        let warningDate: Date
        if daysLeft > 3 {
            warningDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(10 * 3600)
        } else {
            warningDate = Calendar.current.startOfDay(for: Date()).addingTimeInterval(9 * 3600)
        }

        guard warningDate > Date() else { return }

        let urgency = daysLeft <= 3 ? "Mama Bitmek Üzere!" : "Mama Azalıyor"
        scheduleNotification(
            id: "food-\(food.id.uuidString)",
            title: urgency,
            body: "\(pet.name)'in \(food.brand) maması tahminen \(daysLeft) gün içinde bitecek.",
            date: warningDate
        )
    }

    private func scheduleWeightCheckReminder(for pet: Pet) {
        let lastDate = pet.weightLogs.sorted { $0.date > $1.date }.first?.date
        let daysSince = lastDate.map { Calendar.current.dateComponents([.day], from: $0, to: Date()).day ?? 0 } ?? 30
        guard daysSince >= 14 else { return }

        var components = DateComponents()
        components.weekday = 1
        components.hour = 10
        scheduleRepeating(
            id: "weight-\(pet.id.uuidString)",
            title: "Kilo Takibi",
            body: "\(pet.name)'in kilosunu kontrol etmenin zamanı geldi!",
            dateComponents: components
        )
    }

    private func scheduleMonthlySpendingSummary() {
        var components = DateComponents()
        components.day = 1
        components.hour = 10
        scheduleRepeating(
            id: "monthly-spending",
            title: "Aylık Harcama Özeti",
            body: "Geçen ayın harcama özetiniz hazır. Detayları görmek için dokunun.",
            dateComponents: components
        )
    }

    private func scheduleNotification(id: String, title: String, body: String, date: Date) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    private func scheduleRepeating(id: String, title: String, body: String, dateComponents: DateComponents) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }

    func cancelAllNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
    }
}
