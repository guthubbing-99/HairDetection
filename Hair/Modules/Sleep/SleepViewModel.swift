import SwiftUI
import SwiftData

@MainActor
class SleepViewModel: ObservableObject {
    @Published var recentRecords: [SleepRecord] = []
    @Published var todayRecord: SleepRecord?

    private var modelContext: ModelContext?

    func setup(context: ModelContext) {
        modelContext = context
        refresh()
    }

    func refresh() {
        cleanOldRecords()
        fetchTodayStatus()
        fetchRecentRecords()
    }

    func deleteRecord(_ record: SleepRecord) {
        guard let context = modelContext else { return }
        context.delete(record)
        try? context.save()
        refresh()
    }

    func cleanOldRecords() {
        guard let context = modelContext else { return }
        let today = Calendar.current.startOfDay(for: Date())
        guard let cutoff = Calendar.current.date(byAdding: .day, value: -7, to: today) else { return }

        let descriptor = FetchDescriptor<SleepRecord>(
            predicate: #Predicate { $0.date < cutoff }
        )
        if let old = try? context.fetch(descriptor) {
            for record in old {
                context.delete(record)
            }
            if !old.isEmpty {
                try? context.save()
            }
        }
    }

    func remainingDays(for record: SleepRecord) -> Int {
        let today = Calendar.current.startOfDay(for: Date())
        let daysSince = Calendar.current.dateComponents([.day], from: record.date, to: today).day ?? 0
        return max(0, 7 - daysSince)
    }

    // MARK: - Private

    private func fetchTodayStatus() {
        guard let context = modelContext else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<SleepRecord>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow }
        )
        let records = (try? context.fetch(descriptor)) ?? []
        todayRecord = records.first
    }

    private func fetchRecentRecords() {
        guard let context = modelContext else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let weekAgo = Calendar.current.date(byAdding: .day, value: -7, to: today)!

        let descriptor = FetchDescriptor<SleepRecord>(
            predicate: #Predicate { $0.date >= weekAgo },
            sortBy: [SortDescriptor(\.checkInTime, order: .reverse)]
        )
        recentRecords = (try? context.fetch(descriptor)) ?? []
    }
}
