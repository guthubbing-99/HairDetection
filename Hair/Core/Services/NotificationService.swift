import UserNotifications

class NotificationService {
    static let shared = NotificationService()

    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            return try await UNUserNotificationCenter.current()
                .requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleReminder(title: String, body: String, hour: Int, minute: Int, identifier: String? = nil) async {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        var components = DateComponents()
        components.hour = hour
        components.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let id = identifier ?? UUID().uuidString
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)

        try? await UNUserNotificationCenter.current().add(request)
    }

    func scheduleAllDefaults() async {
        await scheduleReminder(
            title: "梳头打卡", body: "今天别忘了梳头养发哦",
            hour: 21, minute: 3, identifier: "comb.reminder"
        )
        await scheduleReminder(
            title: "用药打卡", body: "按时用药，坚持就是胜利",
            hour: 9, minute: 7, identifier: "medication.reminder"
        )
        await scheduleReminder(
            title: "睡眠打卡", body: "该准备睡觉了，熬夜伤发",
            hour: 22, minute: 37, identifier: "sleep.reminder"
        )
    }
}
