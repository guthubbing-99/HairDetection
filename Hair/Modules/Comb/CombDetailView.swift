import SwiftUI
import SwiftData

struct CombDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var notificationService: NotificationService
    @StateObject private var viewModel = CombViewModel()

    var body: some View {
        ZStack {
            if viewModel.hasAnyRecords {
                ScrollView {
                    VStack(spacing: 24) {
                        todaySection
                        calendarSection
                        trendSection
                    }
                    .padding()
                }
            } else {
                EmptyStateView(
                    icon: "comb.fill",
                    title: "开始梳头打卡",
                    subtitle: "每天梳头养发护发\n点击下方按钮开始记录",
                    tintColor: .pink
                )
            }

            // Celebration overlay
            CelebrationView(isActive: $viewModel.showCelebration, tintColor: .pink)
        }
        .navigationTitle("梳头打卡")
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.setup(context: modelContext)
        }
    }

    // MARK: - Today Section

    private var todaySection: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color.pink.opacity(0.15), lineWidth: 12)
                    .frame(width: 140, height: 140)

                Circle()
                    .trim(from: 0, to: min(Double(viewModel.todayCount) / 10.0, 1.0))
                    .stroke(Color.pink, style: StrokeStyle(lineWidth: 12, lineCap: .round))
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut(duration: 0.5), value: viewModel.todayCount)

                VStack(spacing: 4) {
                    Text("\(viewModel.todayCount)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                    Text("次梳头")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                    viewModel.checkIn()
                    achievementManager.refresh(context: modelContext)
                }
            }) {
                Label("打卡 +1", systemImage: "comb.fill")
                    .font(.headline)
                    .frame(maxWidth: 200)
                    .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .tint(.pink)

            Divider()
                .padding(.horizontal, 16)

            Toggle(isOn: $notificationService.combReminderEnabled) {
                Label("每日提醒", systemImage: "bell.fill")
                    .font(.subheadline)
            }
            .tint(.pink)
            .padding(.horizontal, 8)
            .onChange(of: notificationService.combReminderEnabled) { _, _ in
                Task { await notificationService.rescheduleAllIfNeeded() }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(spacing: 12) {
            HStack {
                Button {
                    viewModel.changeMonth(by: -1)
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline)
                }

                Text(monthTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)

                Button {
                    viewModel.changeMonth(by: 1)
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                }
            }
            .padding(.horizontal, 8)

            HStack {
                ForEach(["一", "二", "三", "四", "五", "六", "日"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 2), count: 7), spacing: 2) {
                ForEach(viewModel.monthDays) { entry in
                    calendarCell(for: entry)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    @ViewBuilder
    private func calendarCell(for entry: DayEntry) -> some View {
        if entry.isCurrentMonth {
            Text("\(Calendar.current.component(.day, from: entry.date))")
                .font(.caption2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(cellBackground(count: entry.count, isToday: entry.isToday))
                .clipShape(RoundedRectangle(cornerRadius: 4))
        } else {
            Text("\(Calendar.current.component(.day, from: entry.date))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
        }
    }

    private func cellBackground(count: Int, isToday: Bool) -> some View {
        Group {
            if count > 0 {
                let opacity = min(Double(count) * 0.2, 1.0)
                Color.pink.opacity(opacity)
            } else if isToday {
                Color.pink.opacity(0.08)
            } else {
                Color.clear
            }
        }
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: viewModel.currentMonth)
    }

    // MARK: - Trend Section

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("近7天趋势")
                .font(.headline)

            if viewModel.weekTrend.contains(where: { $0.count > 0 }) {
                HStack(alignment: .bottom, spacing: 8) {
                    ForEach(Array(viewModel.weekTrend.enumerated()), id: \.offset) { index, item in
                        VStack(spacing: 4) {
                            Text("\(item.count)")
                                .font(.caption2)
                                .foregroundStyle(item.count > 0 ? .pink : .secondary)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(item.count > 0 ? Color.pink : Color(.systemGray5))
                                .frame(height: max(CGFloat(item.count) * 16, 4))

                            Text(weekdayLabel(for: item.date))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 100)
            } else {
                Text("暂无数据，开始打卡吧")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 32)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func weekdayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter.string(from: date)
    }
}
