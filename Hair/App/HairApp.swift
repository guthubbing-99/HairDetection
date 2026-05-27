import SwiftUI
import SwiftData

@main
struct HairApp: App {
    @StateObject private var registry = ModuleRegistry()
    @StateObject private var overdueManager = SleepOverdueManager()
    @StateObject private var achievementManager = AchievementManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(registry)
                .environmentObject(overdueManager)
                .environmentObject(achievementManager)
                .task {
                    _ = await NotificationService.shared.requestAuthorization()
                    await NotificationService.shared.scheduleAllDefaults()
                }
        }
        .modelContainer(for: [CombRecord.self, SleepRecord.self, MedicationRecord.self])
    }
}
