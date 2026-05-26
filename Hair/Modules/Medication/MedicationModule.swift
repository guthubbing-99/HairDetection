import SwiftUI
import SwiftData

struct MedicationModule: HairModule {
    var id: String { "medication" }
    var displayName: String { "用药打卡" }
    var icon: String { "pills.fill" }
    var tintColor: Color { .orange }
    var cardSize: ModuleCardSize { .large }

    func makeHomeCard() -> AnyView {
        AnyView(MedicationHomeCard())
    }

    func makeDetailView() -> AnyView {
        AnyView(MedicationDetailView())
    }
}

// MARK: - Home Card (Large)

struct MedicationHomeCard: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = MedicationViewModel()

    var body: some View {
        ModuleCardView(
            title: "用药打卡",
            icon: "pills.fill",
            tintColor: .orange,
            size: .large
        ) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("连续天数")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(viewModel.streakDays)")
                            .font(.system(size: 36, weight: .bold, design: .rounded))

                        if viewModel.streakDays > 0 {
                            Text("天")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if viewModel.streakDays > 0 {
                        Text(streakText)
                            .font(.caption)
                            .foregroundStyle(streakColor)
                    } else if !viewModel.hasCheckedInToday {
                        Text("今日还未打卡")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                SparkAnimationView(level: viewModel.streakLevel, days: viewModel.streakDays)
                    .frame(width: 90, height: 90)
                    .scaleEffect(0.6)
            }
        }
        .onAppear {
            viewModel.setup(context: modelContext)
        }
    }

    private var streakText: String {
        switch viewModel.streakLevel {
        case .none: return "开始坚持"
        case .small: return "小火苗"
        case .medium: return "中火"
        case .large: return "大火焰"
        }
    }

    private var streakColor: Color {
        switch viewModel.streakLevel {
        case .none: return .secondary
        case .small: return .orange
        case .medium: return .red
        case .large: return .purple
        }
    }
}
