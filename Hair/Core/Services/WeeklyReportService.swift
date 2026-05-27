import Foundation
import SwiftData

struct WeeklyReport {
    let weekStart: Date
    let weekEnd: Date
    let combCount: Int
    let medicationDays: Int
    let sleepOnTimeDays: Int
    let sleepTotalDays: Int

    var weekRangeText: String {
        let f = DateFormatter()
        f.dateFormat = "M/dd"
        return "\(f.string(from: weekStart)) - \(f.string(from: weekEnd))"
    }
}

struct WeeklyReportService {
    static func generate(context: ModelContext) -> WeeklyReport {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today) else {
            return WeeklyReport(weekStart: today, weekEnd: today, combCount: 0, medicationDays: 0, sleepOnTimeDays: 0, sleepTotalDays: 0)
        }

        let combCount = fetchCombCount(context: context, from: weekStart)
        let medicationDays = fetchMedicationDays(context: context, from: weekStart)
        let (sleepOnTime, sleepTotal) = fetchSleepStats(context: context, from: weekStart)

        return WeeklyReport(
            weekStart: weekStart,
            weekEnd: today,
            combCount: combCount,
            medicationDays: medicationDays,
            sleepOnTimeDays: sleepOnTime,
            sleepTotalDays: sleepTotal
        )
    }

    private static func fetchCombCount(context: ModelContext, from start: Date) -> Int {
        let descriptor = FetchDescriptor<CombRecord>(
            predicate: #Predicate { $0.date >= start }
        )
        let records = (try? context.fetch(descriptor)) ?? []
        return records.reduce(0) { $0 + $1.count }
    }

    private static func fetchMedicationDays(context: ModelContext, from start: Date) -> Int {
        let descriptor = FetchDescriptor<MedicationRecord>(
            predicate: #Predicate { $0.date >= start }
        )
        let records = (try? context.fetch(descriptor)) ?? []
        let days = Set(records.map { Calendar.current.startOfDay(for: $0.date) })
        return days.count
    }

    private static func fetchSleepStats(context: ModelContext, from start: Date) -> (onTime: Int, total: Int) {
        let descriptor = FetchDescriptor<SleepRecord>(
            predicate: #Predicate { $0.date >= start }
        )
        let records = (try? context.fetch(descriptor)) ?? []
        let onTime = records.filter { !$0.isOverdue }.count
        return (onTime, records.count)
    }
}
