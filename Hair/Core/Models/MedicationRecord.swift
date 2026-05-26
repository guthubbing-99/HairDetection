import Foundation
import SwiftData

@Model
class MedicationRecord {
    var id: UUID
    var date: Date
    var checkInTime: Date

    init(date: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.checkInTime = date
    }
}
