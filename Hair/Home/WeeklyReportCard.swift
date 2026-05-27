import SwiftUI

struct WeeklyReportCard: View {
    let report: WeeklyReport

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "chart.bar.fill")
                    .foregroundColor(.blue)
                Text("本周报告")
                    .font(.headline)
                Spacer()
                Text(report.weekRangeText)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 0) {
                statCell(
                    icon: "comb.fill",
                    color: .pink,
                    value: "\(report.combCount)",
                    unit: "次",
                    subtitle: "梳头"
                )

                Divider()
                    .frame(height: 40)

                statCell(
                    icon: "pills.fill",
                    color: .orange,
                    value: "\(report.medicationDays)",
                    unit: "/7天",
                    subtitle: "用药"
                )

                Divider()
                    .frame(height: 40)

                statCell(
                    icon: "moon.zzz.fill",
                    color: .indigo,
                    value: "\(report.sleepOnTimeDays)",
                    unit: "/\(report.sleepTotalDays > 0 ? "\(report.sleepTotalDays)" : "7")天",
                    subtitle: "准时睡"
                )
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
    }

    private func statCell(icon: String, color: Color, value: String, unit: String, subtitle: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .rounded).bold())
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
