import SwiftUI
import SwiftData

struct SleepDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var overdueManager: SleepOverdueManager
    @EnvironmentObject var achievementManager: AchievementManager
    @EnvironmentObject var notificationService: NotificationService
    @StateObject private var viewModel = SleepViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                targetTimeSection
                statusSection
                checkInSection
                historySection
            }
            .padding()
        }
        .navigationTitle("睡眠打卡")
        .background(Color(.systemGroupedBackground))
        .onAppear {
            viewModel.setup(context: modelContext)
            overdueManager.refresh()
        }
    }

    // MARK: - Target Time

    private var targetTimeSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "moon.zzz.fill")
                    .foregroundColor(.indigo)
                Text("目标就寝时间")
                    .font(.headline)
            }

            DatePicker("", selection: $overdueManager.targetTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(.wheel)
                .labelsHidden()
                .frame(height: 120)
                .onChange(of: overdueManager.targetTime) { _, _ in
                    overdueManager.refresh()
                    viewModel.refresh()
                    Task { await notificationService.refreshSleepReminder() }
                }

            Divider()

            Toggle(isOn: $notificationService.sleepReminderEnabled) {
                Label("就寝提醒", systemImage: "bell.fill")
                    .font(.subheadline)
            }
            .tint(.indigo)
            .onChange(of: notificationService.sleepReminderEnabled) { _, enabled in
                Task { await notificationService.rescheduleAllIfNeeded() }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Status

    private var statusSection: some View {
        VStack(spacing: 12) {
            if overdueManager.hasCheckedInToday {
                checkedInStatus
            } else if overdueManager.isOverdue {
                overdueStatus
            } else {
                onTimeStatus
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var onTimeStatus: some View {
        VStack(spacing: 8) {
            Image(systemName: "clock.fill")
                .font(.system(size: 36))
                .foregroundColor(.indigo)

            Text("距离就寝还有")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(timeUntilTarget)
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .foregroundColor(.indigo)

            Text(targetTimeString)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var overdueStatus: some View {
        VStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 36))
                .foregroundColor(.red)

            Text("已超过就寝时间！")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.red)

            Text("已经 \(timeOverTarget)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var checkedInStatus: some View {
        VStack(spacing: 8) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 36))
                .foregroundColor(.green)

            Text("今日已打卡")
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(.green)

            if let record = viewModel.todayRecord {
                Text("打卡时间: \(formatTime(record.checkInTime))")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if record.isOverdue {
                    Text("⚠️ 超过目标时间")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
    }

    // MARK: - Check-in Button

    private var checkInSection: some View {
        Button(action: {
            overdueManager.checkIn()
            viewModel.refresh()
            achievementManager.refresh(context: modelContext)
        }) {
            Label(
                overdueManager.hasCheckedInToday ? "再次打卡" : "睡眠打卡",
                systemImage: overdueManager.hasCheckedInToday ? "checkmark.circle.fill" : "moon.zzz.fill"
            )
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
        }
        .buttonStyle(.borderedProminent)
        .tint(overdueManager.hasCheckedInToday ? .green : .indigo)
    }

    // MARK: - History

    private var historySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("最近记录")
                    .font(.headline)
                Spacer()
                Text("保留7天")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }

            if viewModel.recentRecords.isEmpty {
                Text("暂无记录")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                ForEach(viewModel.recentRecords) { record in
                    historyRow(record)
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                withAnimation {
                                    viewModel.deleteRecord(record)
                                }
                            } label: {
                                Label("删除", systemImage: "trash")
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

    @ViewBuilder
    private func historyRow(_ record: SleepRecord) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formatDate(record.date))
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text("目标 \(String(format: "%02d:%02d", record.targetHour, record.targetMinute)) · 打卡 \(formatTime(record.checkInTime))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                if record.isOverdue {
                    Text("⚠️ 超时")
                        .font(.caption)
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                } else {
                    Text("✅ 准时")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }

                let daysLeft = viewModel.remainingDays(for: record)
                if daysLeft <= 2 {
                    Text("\(daysLeft)天后清除")
                        .font(.caption2)
                        .foregroundStyle(daysLeft == 0 ? .red : .secondary)
                }
            }
        }
    }

    // MARK: - Computed Properties

    private var timeUntilTarget: String {
        let now = Date()
        let calendar = Calendar.current
        let targetComponents = calendar.dateComponents([.hour, .minute], from: overdueManager.targetTime)
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)

        let targetMinutes = (targetComponents.hour ?? 0) * 60 + (targetComponents.minute ?? 0)
        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)

        let diff = targetMinutes - nowMinutes
        if diff <= 0 { return "已到时间" }
        let hours = diff / 60
        let minutes = diff % 60
        if hours > 0 {
            return "\(hours) 小时 \(minutes) 分"
        }
        return "\(minutes) 分钟"
    }

    private var timeOverTarget: String {
        let now = Date()
        let calendar = Calendar.current
        let targetComponents = calendar.dateComponents([.hour, .minute], from: overdueManager.targetTime)
        let nowComponents = calendar.dateComponents([.hour, .minute], from: now)

        let targetMinutes = (targetComponents.hour ?? 0) * 60 + (targetComponents.minute ?? 0)
        let nowMinutes = (nowComponents.hour ?? 0) * 60 + (nowComponents.minute ?? 0)

        let diff = nowMinutes - targetMinutes
        let hours = diff / 60
        let minutes = diff % 60
        if hours > 0 {
            return "超时 \(hours) 小时 \(minutes) 分"
        }
        return "超时 \(minutes) 分钟"
    }

    private var targetTimeString: String {
        let components = Calendar.current.dateComponents([.hour, .minute], from: overdueManager.targetTime)
        return String(format: "目标 %02d:%02d", components.hour ?? 23, components.minute ?? 0)
    }

    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/dd"
        return formatter.string(from: date)
    }
}
