import SwiftUI
import SwiftData

@main
struct HairApp: App {
    @StateObject private var registry = ModuleRegistry()
    @StateObject private var overdueManager = SleepOverdueManager()
    @StateObject private var achievementManager = AchievementManager()
    @StateObject private var notificationService = NotificationService.shared

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(registry)
                .environmentObject(overdueManager)
                .environmentObject(achievementManager)
                .environmentObject(notificationService)
                .task {
                    await notificationService.bootstrap()
                }
        }
        .modelContainer(for: [CombRecord.self, SleepRecord.self, MedicationRecord.self])
    }
}
