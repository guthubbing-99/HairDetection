import SwiftUI
import SwiftData

struct DayEntry: Identifiable {
    let id = UUID()
    let date: Date
    let count: Int
    let isToday: Bool
    let isCurrentMonth: Bool
}

@MainActor
class CombViewModel: ObservableObject {
    @Published var todayCount: Int = 0
    @Published var monthDays: [DayEntry] = []
    @Published var weekTrend: [(date: Date, count: Int)] = []
    @Published var currentMonth: Date = Date()
    @Published var hasAnyRecords: Bool = false
    @Published var showCelebration: Bool = false

    private var modelContext: ModelContext?

    func setup(context: ModelContext) {
        modelContext = context
        refresh()
    }

    func refresh() {
        fetchTodayCount()
        fetchMonthCalendar()
        fetchWeekTrend()
        checkHasRecords()
    }

    func checkIn() {
        guard let context = modelContext else { return }
        let today = Calendar.current.startOfDay(for: Date())

        let descriptor = FetchDescriptor<CombRecord>(
            predicate: #Predicate { $0.date >= today }
        )
        if let existing = try? context.fetch(descriptor).first {
            existing.count += 1
        } else {
            context.insert(CombRecord(date: today, count: 1))
        }
        try? context.save()
        refresh()

        showCelebration = true
        // Haptic: milestones get stronger feedback
        let newCount = todayCount
        if newCount == 10 {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if newCount % 5 == 0 {
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        } else {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
    }

    func changeMonth(by offset: Int) {
        if let newMonth = Calendar.current.date(byAdding: .month, value: offset, to: currentMonth) {
            currentMonth = newMonth
            fetchMonthCalendar()
        }
    }

    // MARK: - Private

    private func checkHasRecords() {
        guard let context = modelContext else { return }
        var descriptor = FetchDescriptor<CombRecord>()
        descriptor.fetchLimit = 1
        hasAnyRecords = ((try? context.fetch(descriptor).first) != nil)
    }

    private func fetchTodayCount() {
        guard let context = modelContext else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<CombRecord>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow }
        )
        todayCount = (try? context.fetch(descriptor).first?.count) ?? 0
    }

    private func fetchMonthCalendar() {
        guard let context = modelContext else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let monthStart = calendar.dateInterval(of: .month, for: currentMonth)?.start,
              let monthEnd = calendar.dateInterval(of: .month, for: currentMonth)?.end
        else { return }

        let weekday = calendar.component(.weekday, from: monthStart)
        let daysFromMonday = (weekday + 5) % 7
        let gridStart = calendar.date(byAdding: .day, value: -daysFromMonday, to: monthStart)!

        let descriptor = FetchDescriptor<CombRecord>(
            predicate: #Predicate { $0.date >= gridStart && $0.date < monthEnd }
        )
        let records = (try? context.fetch(descriptor)) ?? []

        var days: [DayEntry] = []
        for i in 0..<42 {
            let date = calendar.date(byAdding: .day, value: i, to: gridStart)!
            let dayStart = calendar.startOfDay(for: date)
            let count = records.first(where: { calendar.startOfDay(for: $0.date) == dayStart })?.count ?? 0
            let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
            days.append(DayEntry(
                date: date,
                count: count,
                isToday: calendar.isDate(date, inSameDayAs: today),
                isCurrentMonth: isCurrentMonth
            ))
        }
        monthDays = days
    }

    private func fetchWeekTrend() {
        guard let context = modelContext else { return }
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        guard let weekStart = calendar.date(byAdding: .day, value: -6, to: today) else { return }

        let descriptor = FetchDescriptor<CombRecord>(
            predicate: #Predicate { $0.date >= weekStart }
        )
        let records = (try? context.fetch(descriptor)) ?? []

        var trend: [(Date, Int)] = []
        for i in 0..<7 {
            let day = calendar.date(byAdding: .day, value: i, to: weekStart)!
            let dayStart = calendar.startOfDay(for: day)
            let count = records.first(where: { calendar.startOfDay(for: $0.date) == dayStart })?.count ?? 0
            trend.append((day, count))
        }
        weekTrend = trend
    }
}
