import UserNotifications
import SwiftUI
import OSLog

@MainActor
class NotificationService: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationService()

    private let logger = Logger(subsystem: "com.hair.app", category: "NotificationService")

    /// Published when user taps a notification — the module ID to navigate to.
    @Published var deepLinkModule: String?
    /// Whether notification permission has been granted.
    @Published var isAuthorized: Bool = false

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
        self.combReminderEnabled = defaults.object(forKey: Key.combEnabled) as? Bool ?? true
        self.medicationReminderEnabled = defaults.object(forKey: Key.medicationEnabled) as? Bool ?? true
        self.sleepReminderEnabled = defaults.object(forKey: Key.sleepEnabled) as? Bool ?? true
        super.init()
        UNUserNotificationCenter.current().delegate = self
    }

    /// Call once at app launch.
    func bootstrap() async {
        let granted = await requestAuthorization()
        isAuthorized = granted
        logger.info("Notification authorization: \(granted)")
        await refreshAuthorizationStatus()
        await rescheduleAllIfNeeded()
        logPendingNotifications()
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
            isAuthorized = granted
            logger.info("Notification permission granted: \(granted)")
            return granted
        } catch {
            logger.error("Notification permission error: \(error.localizedDescription)")
            return false
        }
    }

    func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        isAuthorized = settings.authorizationStatus == .authorized
        logger.info("Current authorization status: \(String(describing: settings.authorizationStatus.rawValue))")
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

    // MARK: - Testing

    /// Fires a test notification after `seconds` seconds — for verifying the system works.
    func sendTestNotification(delay seconds: TimeInterval = 5) {
        let content = UNMutableNotificationContent()
        content.title = "测试通知"
        content.body = "如果你看到这条消息，说明通知系统正常工作"
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(seconds, 1), repeats: false)
        let request = UNNotificationRequest(identifier: "test.notification", content: content, trigger: trigger)

        UNUserNotificationCenter.current().add(request) { error in
            if let error {
                Task { @MainActor in
                    self.logger.error("Test notification failed: \(error.localizedDescription)")
                }
            } else {
                Task { @MainActor in
                    self.logger.info("Test notification scheduled to fire in \(seconds)s")
                }
            }
        }
    }

    /// Log all currently pending notifications to console.
    func logPendingNotifications() {
        UNUserNotificationCenter.current().getPendingNotificationRequests { [weak self] requests in
            guard let self else { return }
            Task { @MainActor in
                self.logger.info("Pending notifications: \(requests.count)")
                for req in requests {
                    let trigger = req.trigger.flatMap { String(describing: $0) } ?? "nil"
                    self.logger.info("  [\(req.identifier)] \(req.content.title) — trigger: \(trigger)")
                }
            }
        }
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        logger.info("All notifications cancelled")
    }

    // MARK: - UNUserNotificationCenterDelegate

    nonisolated func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }

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

        do {
            try await UNUserNotificationCenter.current().add(request)
            let nextDate = trigger.nextTriggerDate().map { $0.formatted() } ?? "unknown"
            logger.info("Scheduled [\(identifier)] at \(hour):\(String(format: "%02d", minute)), next fire: \(nextDate)")
        } catch {
            logger.error("Failed to schedule [\(identifier)]: \(error.localizedDescription)")
        }
    }

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
