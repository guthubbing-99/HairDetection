import SwiftUI
import SwiftData

@main
struct HairApp: App {
    @StateObject private var registry = ModuleRegistry()
    @StateObject private var overdueManager = SleepOverdueManager()

    var body: some Scene {
        WindowGroup {
            HomeView()
                .environmentObject(registry)
                .environmentObject(overdueManager)
        }
        .modelContainer(for: [CombRecord.self, SleepRecord.self, MedicationRecord.self])
    }
}
