import Foundation
import SwiftData

@Model
class PhotoLog {
    var id: UUID
    var imageData: Data
    var caption: String
    var date: Date
    var pet: Pet?

    init(imageData: Data, caption: String = "", date: Date = Date()) {
        self.id = UUID()
        self.imageData = imageData
        self.caption = caption
        self.date = date
    }
}
