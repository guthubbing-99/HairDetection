import Foundation
import SwiftData

@Model
class SleepRecord {
    var id: UUID
    var date: Date
    var targetHour: Int
    var targetMinute: Int
    var checkInTime: Date
    var isOverdue: Bool

    init(targetHour: Int, targetMinute: Int, checkInTime: Date = Date()) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: checkInTime)
        self.targetHour = targetHour
        self.targetMinute = targetMinute
        self.checkInTime = checkInTime

        let calendar = Calendar.current
        let nowComponents = calendar.dateComponents([.hour, .minute], from: checkInTime)
        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)
        let targetMinutes = targetHour * 60 + targetMinute
        self.isOverdue = nowMinutes > targetMinutes
    }
}
