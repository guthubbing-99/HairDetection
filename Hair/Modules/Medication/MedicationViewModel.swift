import SwiftUI
import SwiftData

struct MedDayEntry: Identifiable {
    let id = UUID()
    let date: Date
    let isCheckedIn: Bool
    let isToday: Bool
    let isCurrentMonth: Bool
}

@MainActor
class MedicationViewModel: ObservableObject {
    @Published var streakDays: Int = 0
    @Published var streakLevel: StreakLevel = .none
    @Published var hasCheckedInToday: Bool = false
    @Published var monthDays: [MedDayEntry] = []
    @Published var currentMonth: Date = Date()
    @Published var recentRecords: [MedicationRecord] = []
    @Published var hasAnyRecords: Bool = false
    @Published var showCelebration: Bool = false

    private var modelContext: ModelContext?

    func setup(context: ModelContext) {
        modelContext = context
        refresh()
    }

    func refresh() {
        calculateStreak()
        fetchMonthCalendar()
        fetchRecentRecords()
        checkHasRecords()
    }

    func checkIn() {
        guard let context = modelContext else { return }
        let today = Calendar.current.startOfDay(for: Date())

        let descriptor = FetchDescriptor<MedicationRecord>(
            predicate: #Predicate { $0.date == today }
        )
        if (try? context.fetch(descriptor).first) != nil {
            return
        }

        let previousLevel = streakLevel

        context.insert(MedicationRecord())
        try? context.save()
        refresh()

        showCelebration = true

        // Haptic: spark upgrade gets special treatment
        if previousLevel != streakLevel && streakLevel != .none {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            // Extra heavy for dramatic upgrades
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }
        } else {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
        var descriptor = FetchDescriptor<MedicationRecord>()
        descriptor.fetchLimit = 1
        hasAnyRecords = ((try? context.fetch(descriptor).first) != nil)
    }

    // MARK: - Streak

    private func calculateStreak() {
        guard let context = modelContext else { return }

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let allDescriptor = FetchDescriptor<MedicationRecord>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let allRecords = (try? context.fetch(allDescriptor)) ?? []

        hasCheckedInToday = allRecords.first?.date == today

        var streak = 0
        var checkDate = today

        for record in allRecords {
            let recordDate = calendar.startOfDay(for: record.date)
            if calendar.isDate(recordDate, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if recordDate < checkDate {
                break
            }
        }

        streakDays = streak
        streakLevel = StreakCalculator.calculate(days: streak)
    }

    // MARK: - Calendar

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

        let descriptor = FetchDescriptor<MedicationRecord>(
            predicate: #Predicate { $0.date >= gridStart && $0.date < monthEnd }
        )
        let records = (try? context.fetch(descriptor)) ?? []

        let checkedInDates = Set(records.map { calendar.startOfDay(for: $0.date) })

        var days: [MedDayEntry] = []
        for i in 0..<42 {
            let date = calendar.date(byAdding: .day, value: i, to: gridStart)!
            let dayStart = calendar.startOfDay(for: date)
            let isCurrentMonth = calendar.isDate(date, equalTo: currentMonth, toGranularity: .month)
            days.append(MedDayEntry(
                date: date,
                isCheckedIn: checkedInDates.contains(dayStart),
                isToday: calendar.isDate(date, inSameDayAs: today),
                isCurrentMonth: isCurrentMonth
            ))
        }
        monthDays = days
    }

    private func fetchRecentRecords() {
        guard let context = modelContext else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!

        let descriptor = FetchDescriptor<MedicationRecord>(
            predicate: #Predicate { $0.date >= weekAgo },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        recentRecords = (try? context.fetch(descriptor)) ?? []
    }
}
