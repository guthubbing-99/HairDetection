import SwiftUI
import SwiftData

struct SleepModule: HairModule {
    var id: String { "sleep" }
    var displayName: String { "睡眠打卡" }
    var icon: String { "moon.zzz.fill" }
    var tintColor: Color { .indigo }
    var cardSize: ModuleCardSize { .small }

    func makeHomeCard() -> AnyView {
        AnyView(SleepHomeCard())
    }

    func makeDetailView() -> AnyView {
        AnyView(SleepDetailView())
    }
}

// MARK: - Home Card

struct SleepHomeCard: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var overdueManager: SleepOverdueManager

    var body: some View {
        ModuleCardView(
            title: "睡眠打卡",
            icon: "moon.zzz.fill",
            tintColor: .indigo,
            size: .small
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text("目标就寝")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                HStack(spacing: 4) {
                    Text(targetTimeString)
                        .font(.title2)
                        .fontWeight(.bold)
                    if overdueManager.isOverdue && !overdueManager.hasCheckedInToday {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                    } else if overdueManager.hasCheckedInToday {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .onAppear {
            overdueManager.refresh()
        }
    }

    private var targetTimeString: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: overdueManager.targetTime)
        return String(format: "%02d:%02d", components.hour ?? 23, components.minute ?? 0)
    }
}
