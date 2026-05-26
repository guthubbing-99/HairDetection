import SwiftUI
import SwiftData

struct MedicationDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = MedicationViewModel()

    var body: some View {
        ZStack {
            if viewModel.hasAnyRecords {
                ScrollView {
                    VStack(spacing: 24) {
                        streakSection
                        checkInSection
                        calendarSection
                        recentSection
                    }
                    .padding()
                }
            } else {
                EmptyStateView(
                    icon: "pills.fill",
                    title: "开始用药打卡",
                    subtitle: "每天坚持用药，守护秀发健康\n连续打卡还能获得火花奖励",
                    tintColor: .orange
                )
            }

            CelebrationView(isActive: $viewModel.showCelebration, tintColor: .orange)
        }
        .navigationTitle("用药打卡")
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.setup(context: modelContext)
        }
    }

    // MARK: - Streak Section

    private var streakSection: some View {
        VStack(spacing: 16) {
            SparkAnimationView(level: viewModel.streakLevel, days: viewModel.streakDays)

            VStack(spacing: 6) {
                HStack(spacing: 4) {
                    Text("\(viewModel.streakDays)")
                        .font(.system(size: 44, weight: .bold, design: .rounded))
                    Text("天")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                }

                Text(streakLabel)
                    .font(.subheadline)
                    .foregroundStyle(streakLabelColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(streakLabelColor.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                // Show next milestone target
                if let nextMilestone = nextMilestoneText {
                    Text(nextMilestone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Check-in Button

    private var checkInSection: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.5)) {
                viewModel.checkIn()
            }
        }) {
            Label(
                viewModel.hasCheckedInToday ? "今日已打卡 ✓" : "今日打卡",
                systemImage: viewModel.hasCheckedInToday ? "checkmark.circle.fill" : "pills.fill"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(viewModel.hasCheckedInToday ? .green : .orange)
        .disabled(viewModel.hasCheckedInToday)
    }

    // MARK: - Calendar

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

    private func calendarCell(for entry: MedDayEntry) -> some View {
        Group {
            if entry.isCurrentMonth {
                Text("\(Calendar.current.component(.day, from: entry.date))")
                    .font(.caption2)
                    .fontWeight(entry.isCheckedIn ? .bold : .regular)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(cellBackground(entry))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .foregroundColor(entry.isCheckedIn ? .white : .primary)
            } else {
                Text("\(Calendar.current.component(.day, from: entry.date))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
            }
        }
    }

    private func cellBackground(_ entry: MedDayEntry) -> some View {
        if entry.isCheckedIn {
            return AnyView(Color.orange)
        } else if entry.isToday {
            return AnyView(Color.orange.opacity(0.08))
        }
        return AnyView(Color.clear)
    }

    private var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年 M月"
        return formatter.string(from: viewModel.currentMonth)
    }

    // MARK: - Recent Records

    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近记录")
                .font(.headline)

            if viewModel.recentRecords.isEmpty {
                Text("暂无记录，开始用药打卡吧")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.recentRecords) { record in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.title3)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(formatDate(record.date))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("打卡 \(formatTime(record.checkInTime))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()

                        let daysAgo = Calendar.current.dateComponents([.day], from: record.date, to: Calendar.current.startOfDay(for: Date())).day ?? 0
                        if daysAgo == 0 {
                            Text("今天")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        } else {
                            Text("\(daysAgo)天前")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }

                    if record.id != viewModel.recentRecords.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helpers

    private var streakLabel: String {
        switch viewModel.streakLevel {
        case .none:
            return viewModel.streakDays == 0 ? "开始打卡" : "坚持就是胜利"
        case .small: return "小火苗"
        case .medium: return "中火"
        case .large: return "大火焰"
        }
    }

    private var streakLabelColor: Color {
        switch viewModel.streakLevel {
        case .none: return .secondary
        case .small: return .orange
        case .medium: return .red
        case .large: return .purple
        }
    }

    private var nextMilestoneText: String? {
        switch viewModel.streakDays {
        case 0: return "坚持3天获得小火苗"
        case 1...2: return "再坚持\(3 - viewModel.streakDays)天获得小火苗"
        case 3...6: return "再坚持\(7 - viewModel.streakDays)天升级中火"
        case 7...29: return "再坚持\(30 - viewModel.streakDays)天升级大火焰"
        default: return nil
        }
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/dd"
        return formatter.string(from: date)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
}
