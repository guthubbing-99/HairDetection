import SwiftUI

struct AchievementCard: View {
    @ObservedObject var manager: AchievementManager

    private let allAchievements = Achievement.allCases

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: "trophy.fill")
                    .foregroundColor(.yellow)
                Text("成就")
                    .font(.headline)
                Spacer()
                Text("\(unlockedCount)/\(allAchievements.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if unlockedCount == allAchievements.count {
                allUnlockedView
            } else {
                progressView
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, y: 2)
        .overlay(alignment: .top) {
            if let new = manager.newlyUnlocked {
                unlockBanner(new)
                    .offset(y: -44)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: manager.newlyUnlocked != nil)
    }

    // MARK: - Subviews

    private var allUnlockedView: some View {
        HStack(spacing: 4) {
            ForEach(allAchievements, id: \.rawValue) { achievement in
                achievementIcon(achievement, size: 28)
            }
        }
    }

    private var progressView: some View {
        VStack(spacing: 10) {
            // Show next unlockable
            if let next = nextUnlockable {
                HStack(spacing: 8) {
                    Image(systemName: next.icon)
                        .font(.title3)
                        .foregroundColor(.gray)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(next.title)
                            .font(.subheadline)
                            .fontWeight(.medium)
                        Text(next.description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(10)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Progress dots
            HStack(spacing: 4) {
                ForEach(allAchievements, id: \.rawValue) { achievement in
                    Circle()
                        .fill(manager.unlocked.contains(achievement.rawValue)
                              ? Color.yellow : Color(.systemGray4))
                        .frame(width: 8, height: 8)
                }
            }
        }
    }

    private func unlockBanner(_ achievement: Achievement) -> some View {
        HStack(spacing: 8) {
            Image(systemName: achievement.icon)
                .font(.title3)
                .foregroundColor(.yellow)
            VStack(alignment: .leading, spacing: 1) {
                Text("成就解锁!")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(achievement.title)
                    .font(.subheadline)
                    .fontWeight(.bold)
            }
            Spacer()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.12), radius: 8, y: 4)
    }

    private func achievementIcon(_ achievement: Achievement, size: CGFloat) -> some View {
        Image(systemName: achievement.icon)
            .font(.system(size: size * 0.5))
            .frame(width: size, height: size)
            .background(Color.yellow.opacity(0.2))
            .foregroundColor(.yellow)
            .clipShape(Circle())
    }

    // MARK: - Computed

    private var unlockedCount: Int {
        allAchievements.filter { manager.unlocked.contains($0.rawValue) }.count
    }

    private var nextUnlockable: Achievement? {
        allAchievements.first { !manager.unlocked.contains($0.rawValue) }
    }
}
