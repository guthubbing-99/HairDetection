import UserNotifications
import SwiftUI

@MainActor
class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    /// Published when user taps a notification — the module ID to navigate to.
    @Published var deepLinkModule: String?

    // MARK: - UserDefaults toggles

    @Published var combReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(combReminderEnabled, forKey: Key.combEnabled) }
    }
    @Published var medicationReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(medicationReminderEnabled, forKey: Key.medicationEnabled) }
    }
    @Published var sleepReminderEnabled: Bool {
        didSet { UserDefaults.standard.set(sleepReminderEnabled, forKey: Key.sleepEnabled) }
    }

    private override init() {
        let defaults = UserDefaults.standard
        // Default to true on first launch when key is missing
        self.combReminderEnabled = defaults.object(forKey: Key.combEnabled) as? Bool ?? true
        self.medicationReminderEnabled = defaults.object(forKey: Key.medicationEnabled) as? Bool ?? true
        self.sleepReminderEnabled = defaults.object(forKey: Key.sleepEnabled) as? Bool ?? true
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Call once at app launch to request permission and schedule defaults.
    func bootstrap() async {
        _ = await requestAuthorization()
        await rescheduleAllIfNeeded()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    // MARK: - Public scheduling

    func rescheduleAllIfNeeded() async {
        let center = UNUserNotificationCenter.current()

        if combReminderEnabled {
            await schedule(
                identifier: Identifier.comb,
                title: "梳头打卡",
                body: "今天别忘了梳头养发哦",
                hour: 21, minute: 3
            )
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [Identifier.comb])
        }

        if medicationReminderEnabled {
            await schedule(
                identifier: Identifier.medication,
                title: "用药打卡",
                body: "按时用药，坚持就是胜利",
                hour: 9, minute: 7
            )
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [Identifier.medication])
        }

        if sleepReminderEnabled {
            let (h, m) = sleepReminderTime()
            await schedule(
                identifier: Identifier.sleep,
                title: "睡眠打卡",
                body: "该准备睡觉了，熬夜伤发",
                hour: h, minute: m
            )
        } else {
            center.removePendingNotificationRequests(withIdentifiers: [Identifier.sleep])
        }
    }

    /// Reschedule sleep reminder when target time changes.
    func refreshSleepReminder() async {
        guard sleepReminderEnabled else { return }
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.sleep])
        let (h, m) = sleepReminderTime()
        await schedule(
            identifier: Identifier.sleep,
            title: "睡眠打卡",
            body: "该准备睡觉了，熬夜伤发",
            hour: h, minute: m
        )
    }

    /// Remove all pending notifications.
    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Show notification banner even when app is in foreground.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

    /// Handle notification tap — deep link to the relevant module.
    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let id = response.notification.request.identifier
        let module: String? = {
            switch id {
            case Identifier.comb: return "comb"
            case Identifier.medication: return "medication"
            case Identifier.sleep: return "sleep"
            default: return nil
            }
        }()
        if let module {
            Task { @MainActor in
                self.deepLinkModule = module
            }
        }
        completionHandler()
    }

    // MARK: - Private

    private func schedule(identifier: String, title: String, body: String, hour: Int, minute: Int) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }

    /// Returns (hour, minute) 30 minutes before the user's saved target time.
    private func sleepReminderTime() -> (Int, Int) {
        let target = SleepOverdueManager.loadTargetTime()
        let calendar = Calendar.current
        guard let earlier = calendar.date(byAdding: .minute, value: -30, to: target) else {
            return (22, 0)
        }
        let h = calendar.component(.hour, from: earlier)
        let m = calendar.component(.minute, from: earlier)
        return (h, m)
    }

    // MARK: - Constants

    private enum Key {
        static let combEnabled = "NotificationService.combEnabled"
        static let medicationEnabled = "NotificationService.medicationEnabled"
        static let sleepEnabled = "NotificationService.sleepEnabled"
    }

    private enum Identifier {
        static let comb = "comb.reminder"
        static let medication = "medication.reminder"
        static let sleep = "sleep.reminder"
    }
}
