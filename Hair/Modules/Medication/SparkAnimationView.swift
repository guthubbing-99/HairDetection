import SwiftUI

struct SparkAnimationView: View {
    let level: StreakLevel
    let days: Int

    @State private var isPulsing = false

    var body: some View {
        ZStack {
            // Glow layers
            ForEach(0..<glowCount, id: \.self) { i in
                Image(systemName: "flame.fill")
                    .font(.system(size: flameSize))
                    .foregroundColor(glowColors[min(i, glowColors.count - 1)])
                    .blur(radius: CGFloat(8 + i * 6))
                    .scaleEffect(isPulsing ? 1.0 + CGFloat(i) * 0.08 : 1.0)
                    .opacity(0.4 - CGFloat(i) * 0.1)
            }

            // Main flame
            Image(systemName: "flame.fill")
                .font(.system(size: flameSize))
                .foregroundStyle(flameGradient)
                .shadow(color: glowColors.first ?? .orange, radius: 20)
                .scaleEffect(isPulsing ? 1.08 : 0.95)
                .animation(
                    .easeInOut(duration: pulseDuration).repeatForever(autoreverses: true),
                    value: isPulsing
                )
        }
        .frame(width: 160, height: 160)
        .onAppear { isPulsing = true }
    }

    // MARK: - Level-dependent properties

    private var glowCount: Int {
        switch level {
        case .none: return 0
        case .small: return 1
        case .medium: return 2
        case .large: return 3
        }
    }

    private var flameSize: CGFloat {
        switch level {
        case .none: return 50
        case .small: return 60
        case .medium: return 70
        case .large: return 80
        }
    }

    private var pulseDuration: Double {
        switch level {
        case .none: return 1.5
        case .small: return 1.2
        case .medium: return 0.9
        case .large: return 0.6
        }
    }

    private var glowColors: [Color] {
        switch level {
        case .none: return []
        case .small: return [.orange]
        case .medium: return [.orange, .red]
        case .large: return [.yellow, .orange, .red]
        }
    }

    private var flameGradient: LinearGradient {
        switch level {
        case .none:
            return LinearGradient(colors: [.gray.opacity(0.5), .gray.opacity(0.3)],
                                  startPoint: .bottom, endPoint: .top)
        case .small:
            return LinearGradient(colors: [.orange, .yellow],
                                  startPoint: .bottom, endPoint: .top)
        case .medium:
            return LinearGradient(colors: [.red, .orange, .yellow],
                                  startPoint: .bottom, endPoint: .top)
        case .large:
            return LinearGradient(colors: [.red, .red, .orange, .yellow, .white],
                                  startPoint: .bottom, endPoint: .top)
        }
    }
}
