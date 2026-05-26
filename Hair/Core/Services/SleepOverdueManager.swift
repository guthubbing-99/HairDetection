import SwiftUI
import SwiftData
import Combine

@MainActor
class SleepOverdueManager: ObservableObject {
    @Published var targetTime: Date {
        didSet { saveTargetTime() }
    }
    @Published var isOverdue: Bool = false
    @Published var showExplosion: Bool = false
    @Published var hasCheckedInToday: Bool = false

    private var modelContext: ModelContext?
    private var checkTimer: Timer?
    private var foregroundCancellable: AnyCancellable?
    private var didSetup = false

    init() {
        self.targetTime = Self.loadTargetTime()
    }

    deinit {
        checkTimer?.invalidate()
        foregroundCancellable?.cancel()
    }

    /// Call once from the root view that has the modelContext.
    func setup(context: ModelContext) {
        guard !didSetup else { return }
        didSetup = true
        modelContext = context
        refresh()
        startTimer()
        observeForeground()
    }

    /// Re-check everything now (call after external state changes).
    func refresh() {
        reloadTargetTime()
        fetchTodayStatus()
        checkOverdue()
    }

    func checkIn() {
        guard let context = modelContext else { return }
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: targetTime)
        let hour = components.hour ?? 23
        let minute = components.minute ?? 0

        let record = SleepRecord(targetHour: hour, targetMinute: minute)
        context.insert(record)
        try? context.save()

        showExplosion = false
        refresh()

        // Haptic: satisfying heavy thud when checking in
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }

    // MARK: - Private

    private func startTimer() {
        checkTimer?.invalidate()
        // Use a run loop timer that fires even during tracking/scrolling
        checkTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkOverdue()
            }
        }
        // Ensure timer fires during scroll too
        if let timer = checkTimer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private func observeForeground() {
        foregroundCancellable = NotificationCenter.default
            .publisher(for: UIApplication.willEnterForegroundNotification)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else { return }
                // When returning to foreground, immediately re-check and restart timer
                self.fetchTodayStatus()
                self.checkOverdue()
                self.startTimer()
            }
    }

    private func checkOverdue() {
        guard !hasCheckedInToday else {
            if isOverdue || showExplosion {
                isOverdue = false
                showExplosion = false
            }
            return
        }

        let calendar = Calendar.current
        let targetComponents = calendar.dateComponents([.hour, .minute], from: targetTime)
        let nowComponents = calendar.dateComponents([.hour, .minute], from: Date())

        guard let th = targetComponents.hour, let tm = targetComponents.minute,
              let nh = nowComponents.hour, let nm = nowComponents.minute else { return }

        let targetMinutes = th * 60 + tm
        let nowMinutes = nh * 60 + nm

        if nowMinutes >= targetMinutes {
            isOverdue = true
            showExplosion = true
        }
    }

    private func fetchTodayStatus() {
        guard let context = modelContext else { return }
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!

        let descriptor = FetchDescriptor<SleepRecord>(
            predicate: #Predicate { $0.date >= today && $0.date < tomorrow }
        )
        let records = (try? context.fetch(descriptor)) ?? []
        hasCheckedInToday = !records.isEmpty
    }

    private func reloadTargetTime() {
        let saved = Self.loadTargetTime()
        if targetTime != saved {
            targetTime = saved
        }
    }

    // MARK: - Persistence

    private static let targetTimeKey = "SleepModule.targetTime"

    private func saveTargetTime() {
        let hour = Calendar.current.component(.hour, from: targetTime)
        let minute = Calendar.current.component(.minute, from: targetTime)
        let dict: [String: Int] = ["hour": hour, "minute": minute]
        UserDefaults.standard.set(dict, forKey: Self.targetTimeKey)
    }

    private static func loadTargetTime() -> Date {
        guard let dict = UserDefaults.standard.dictionary(forKey: targetTimeKey) as? [String: Int],
              let hour = dict["hour"], let minute = dict["minute"] else {
            var components = DateComponents()
            components.hour = 23
            components.minute = 0
            return Calendar.current.date(from: components) ?? Date()
        }
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        return Calendar.current.date(from: components) ?? Date()
    }
}
