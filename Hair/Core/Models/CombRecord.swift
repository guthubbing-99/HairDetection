import Foundation
import SwiftData

@Model
class CombRecord {
    var id: UUID
    var date: Date
    var count: Int

    init(date: Date = Date(), count: Int = 1) {
        self.id = UUID()
        self.date = date
        self.count = count
    }
}
