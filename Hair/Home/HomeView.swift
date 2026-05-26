import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject var registry: ModuleRegistry
    @EnvironmentObject var overdueManager: SleepOverdueManager
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        ZStack {
            NavigationStack {
                ScrollView {
                    VStack(spacing: 16) {
                        headerSection
                        largeCardsSection
                        smallCardsSection
                    }
                    .padding()
                }
                .navigationTitle("头发养护")
                .background(Color(.systemGroupedBackground))
            }
            .opacity(overdueManager.showExplosion ? 0 : 1)

            if overdueManager.showExplosion {
                TextExplosionView(isActive: $overdueManager.showExplosion)

                VStack {
                    Spacer()
                    Button(action: overdueManager.checkIn) {
                        Label("立即打卡睡觉", systemImage: "moon.zzz.fill")
                            .font(.title3)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundColor(.red)
                    .padding(.horizontal, 32)
                    .padding(.bottom, 50)
                }
            }
        }
        .onAppear {
            overdueManager.setup(context: modelContext)
        }
    }

    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("今日打卡")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                Text("保持好习惯，养出秀发")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            Spacer()
        }
    }

    private var largeCardsSection: some View {
        ForEach(registry.largeModules, id: \.id) { module in
            NavigationLink(destination: module.makeDetailView()) {
                module.makeHomeCard()
            }
            .buttonStyle(.plain)
        }
    }

    private var smallCardsSection: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            ForEach(registry.smallModules, id: \.id) { module in
                NavigationLink(destination: module.makeDetailView()) {
                    module.makeHomeCard()
                }
                .buttonStyle(.plain)
            }
        }
    }
}
