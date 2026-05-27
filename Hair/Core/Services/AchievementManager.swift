import SwiftUI
import SwiftData

enum Achievement: String, CaseIterable {
    case firstCheckIn   // 任意模块首次打卡
    case streak7        // 任意模块连续 7 天
    case total30        // 任意模块累计 30 天
    case sleepOnTime7   // 连续 7 天准时入睡
    case tripleCheckIn  // 同一天三模块全打卡
    case comb100        // 梳头累计 100 次

    var icon: String {
        switch self {
        case .firstCheckIn: return "hand.wave.fill"
        case .streak7: return "flame.fill"
        case .total30: return "star.fill"
        case .sleepOnTime7: return "moon.stars.fill"
        case .tripleCheckIn: return "sparkles"
        case .comb100: return "comb.fill"
        }
    }

    var title: String {
        switch self {
        case .firstCheckIn: return "初露锋芒"
        case .streak7: return "坚持一周"
        case .total30: return "满月达成"
        case .sleepOnTime7: return "早鸟达人"
        case .tripleCheckIn: return "三修圆满"
        case .comb100: return "百次梳头"
        }
    }

    var description: String {
        switch self {
        case .firstCheckIn: return "完成首次打卡"
        case .streak7: return "连续打卡 7 天"
        case .total30: return "累计打卡 30 天"
        case .sleepOnTime7: return "连续 7 天准时入睡"
        case .tripleCheckIn: return "一天内完成全部三项打卡"
        case .comb100: return "梳头打卡累计 100 次"
        }
    }
}

@MainActor
class AchievementManager: ObservableObject {
    @Published var unlocked: Set<String> = []
    @Published var newlyUnlocked: Achievement?

    private var didSetup = false

    init() {
        loadFromDisk()
    }

    func setup(context: ModelContext) {
        if !didSetup {
            didSetup = true
            refresh(context: context)
        }
    }

    func refresh(context: ModelContext) {
        let previous = unlocked
        checkAll(context: context)
        if let newly = unlocked.subtracting(previous).first,
           let achievement = Achievement(rawValue: newly) {
            newlyUnlocked = achievement

            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                self?.newlyUnlocked = nil
            }
        }
    }

    // MARK: - Private

    private func checkAll(context: ModelContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let combRecords = fetchAllCombRecords(context: context)
        let medRecords = fetchAllMedicationRecords(context: context)
        let sleepRecords = fetchAllSleepRecords(context: context)

        // firstCheckIn: any record exists
        if !combRecords.isEmpty || !medRecords.isEmpty || !sleepRecords.isEmpty {
            unlock(.firstCheckIn)
        }

        // streak7: check each module for any 7-day run
        if hasStreak(of: 7, records: combRecords.map { calendar.startOfDay(for: $0.date) }, today: today) ||
            hasStreak(of: 7, records: medRecords.map { calendar.startOfDay(for: $0.date) }, today: today) ||
            hasStreak(of: 7, records: sleepRecords.map { calendar.startOfDay(for: $0.date) }, today: today) {
            unlock(.streak7)
        }

        // total30: any module >= 30 unique days
        let combDays = uniqueDays(combRecords)
        let medDays = uniqueDays(medRecords)
        let sleepDays = uniqueDays(sleepRecords)
        if combDays >= 30 || medDays >= 30 || sleepDays >= 30 {
            unlock(.total30)
        }

        // sleepOnTime7: 7 consecutive non-overdue sleep records
        let onTimeDays = sleepRecords.filter { !$0.isOverdue }.map { calendar.startOfDay(for: $0.date) }
        if hasStreak(of: 7, records: onTimeDays, today: today) {
            unlock(.sleepOnTime7)
        }

        // tripleCheckIn: any day where all three have records
        let combDates = Set(combRecords.map { calendar.startOfDay(for: $0.date) })
        let medDates = Set(medRecords.map { calendar.startOfDay(for: $0.date) })
        let sleepDates = Set(sleepRecords.map { calendar.startOfDay(for: $0.date) })
        let allDates = combDates.union(medDates).union(sleepDates)
        if allDates.contains(where: { combDates.contains($0) && medDates.contains($0) && sleepDates.contains($0) }) {
            unlock(.tripleCheckIn)
        }

        // comb100: total comb count >= 100
        let totalCombs = combRecords.reduce(0) { $0 + $1.count }
        if totalCombs >= 100 {
            unlock(.comb100)
        }

        saveToDisk()
    }

    private func unlock(_ achievement: Achievement) {
        unlocked.insert(achievement.rawValue)
    }

    // MARK: - Streak helper

    private func hasStreak(of target: Int, records: [Date], today: Date) -> Bool {
        let sorted = Set(records).sorted(by: >)
        var streak = 0
        var checkDate = today

        for date in sorted {
            let d = Calendar.current.startOfDay(for: date)
            if Calendar.current.isDate(d, inSameDayAs: checkDate) {
                streak += 1
                if streak >= target { return true }
                checkDate = Calendar.current.date(byAdding: .day, value: -1, to: checkDate)!
            } else if d < checkDate {
                break
            }
        }
        return false
    }

    private func uniqueDays(_ records: [any PersistentModel]) -> Int {
        let days = Set(records.compactMap { ($0 as? AnyRecord)?.dateDay })
        return days.count
    }

    // MARK: - Fetch helpers

    private func fetchAllCombRecords(context: ModelContext) -> [CombRecord] {
        var descriptor = FetchDescriptor<CombRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 200
        return (try? context.fetch(descriptor)) ?? []
    }

    private func fetchAllMedicationRecords(context: ModelContext) -> [MedicationRecord] {
        var descriptor = FetchDescriptor<MedicationRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 200
        return (try? context.fetch(descriptor)) ?? []
    }

    private func fetchAllSleepRecords(context: ModelContext) -> [SleepRecord] {
        var descriptor = FetchDescriptor<SleepRecord>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        descriptor.fetchLimit = 200
        return (try? context.fetch(descriptor)) ?? []
    }

    // MARK: - Persistence

    private static let storageKey = "AchievementManager.unlocked"

    private func saveToDisk() {
        UserDefaults.standard.set(Array(unlocked), forKey: Self.storageKey)
    }

    private func loadFromDisk() {
        if let saved = UserDefaults.standard.array(forKey: Self.storageKey) as? [String] {
            unlocked = Set(saved)
        }
    }
}

/// Helper to extract date from any record type
private protocol AnyRecord {
    var dateDay: Date { get }
}

extension CombRecord: AnyRecord {
    var dateDay: Date { Calendar.current.startOfDay(for: date) }
}

extension MedicationRecord: AnyRecord {
    var dateDay: Date { Calendar.current.startOfDay(for: date) }
}

extension SleepRecord: AnyRecord {
    var dateDay: Date { Calendar.current.startOfDay(for: date) }
}
