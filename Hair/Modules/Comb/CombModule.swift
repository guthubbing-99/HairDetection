import SwiftUI
import SwiftData

struct CombModule: HairModule {
    var id: String { "comb" }
    var displayName: String { "梳头打卡" }
    var icon: String { "comb" }
    var tintColor: Color { .pink }
    var cardSize: ModuleCardSize { .small }

    func makeHomeCard() -> AnyView {
        AnyView(CombHomeCard())
    }

    func makeDetailView() -> AnyView {
        AnyView(CombDetailView())
    }
}

// MARK: - Home Card

struct CombHomeCard: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = CombViewModel()

    var body: some View {
        ModuleCardView(
            title: "梳头打卡",
            icon: "comb",
            tintColor: .pink,
            size: .small
        ) {
            VStack(alignment: .leading, spacing: 4) {
                Text("今日梳头")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("\(viewModel.todayCount) 次")
                    .font(.title2)
                    .fontWeight(.bold)
            }
        }
        .onAppear {
            viewModel.setup(context: modelContext)
        }
    }
}
