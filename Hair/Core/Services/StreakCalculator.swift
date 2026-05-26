import Foundation

enum StreakLevel {
    case none
    case small
    case medium
    case large
}

struct StreakCalculator {
    static func calculate(days: Int) -> StreakLevel {
        switch days {
        case 0...2: return .none
        case 3...6: return .small
        case 7...29: return .medium
        default: return .large
        }
    }
}
