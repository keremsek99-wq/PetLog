import Foundation
import SwiftData

@Model
class VetAppointment {
    var id: UUID
    var title: String
    var date: Date
    var vetName: String
    var vetPhone: String
    var location: String
    var notes: String
    var isCompleted: Bool
    var reminderMinutesBefore: Int
    var calendarEventID: String?
    var pet: Pet?

    init(title: String, date: Date, vetName: String = "", vetPhone: String = "",
         location: String = "", notes: String = "", reminderMinutesBefore: Int = 60) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.vetName = vetName
        self.vetPhone = vetPhone
        self.location = location
        self.notes = notes
        self.isCompleted = false
        self.reminderMinutesBefore = reminderMinutesBefore
    }

    var isPast: Bool { date < Date() && !isCompleted }
    var isUpcoming: Bool { date > Date() }
}
