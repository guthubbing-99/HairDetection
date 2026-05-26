import SwiftUI

struct ExplosionItem: Identifiable {
    let id = UUID()
    let text: String
    let x: CGFloat
    let y: CGFloat
    let rotation: Double
    let fontSize: CGFloat
    let color: Color
}

struct TextExplosionView: View {
    @Binding var isActive: Bool
    @State private var items: [ExplosionItem] = []
    @State private var timer: Timer?

    private let phrases = [
        "该睡了！",
        "快去睡！",
        "超时了！",
        "很晚了！",
        "还不睡？",
        "熬夜掉发！",
        "睡觉时间！",
        "关灯！",
        "ZZZ...",
        "晚安！",
    ]

    private let colors: [Color] = [
        .red, .orange, .yellow, .white, .pink,
    ]

    var body: some View {
        ZStack {
            // Red gradient background
            Rectangle()
                .fill(
                    RadialGradient(
                        colors: [Color.red.opacity(0.6), Color.black.opacity(0.95)],
                        center: .center,
                        startRadius: 0,
                        endRadius: 400
                    )
                )
                .ignoresSafeArea()
                .onTapGesture { } // absorb taps to prevent dismissing

            // Exploding texts
            ForEach(items) { item in
                Text(item.text)
                    .font(.system(size: item.fontSize, weight: .heavy, design: .rounded))
                    .foregroundColor(item.color)
                    .rotationEffect(.degrees(item.rotation))
                    .position(x: item.x, y: item.y)
                    .transition(.scale.combined(with: .opacity))
            }

            // Pulsing warning text in center
            VStack(spacing: 16) {
                Text("⚠️ 已过就寝时间 ⚠️")
                    .font(.title2)
                    .fontWeight(.black)
                    .foregroundColor(.white)
                    .opacity(pulseOpacity)

                Text("请立即打卡睡觉！")
                    .font(.headline)
                    .foregroundColor(.white.opacity(0.8))
            }
            .position(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2)
        }
        .onAppear {
            if isActive {
                startExplosion()
            }
        }
        .onChange(of: isActive) { _, active in
            if active {
                startExplosion()
            } else {
                stopExplosion()
            }
        }
        .onDisappear {
            stopExplosion()
        }
    }

    @State private var pulseOpacity: Double = 1.0

    private func startExplosion() {
        // Pulsing animation
        withAnimation(.easeInOut(duration: 0.6).repeatForever(autoreverses: true)) {
            pulseOpacity = 0.3
        }

        // Generate initial burst
        for _ in 0..<12 {
            spawnItem()
        }

        // Continuous spawning
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            Task { @MainActor in
                spawnItem()
                // Trigger haptic feedback
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()

                // Remove old items to prevent memory bloat
                if items.count > 60 {
                    items.removeFirst(20)
                }
            }
        }
    }

    private func stopExplosion() {
        timer?.invalidate()
        timer = nil
        withAnimation(.easeOut(duration: 0.3)) {
            items.removeAll()
        }
        pulseOpacity = 1.0
    }

    private func spawnItem() {
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height

        let item = ExplosionItem(
            text: phrases.randomElement()!,
            x: CGFloat.random(in: 40...(screenWidth - 40)),
            y: CGFloat.random(in: 60...(screenHeight - 100)),
            rotation: Double.random(in: -45...45),
            fontSize: CGFloat.random(in: 28...60),
            color: colors.randomElement()!
        )

        withAnimation(.spring(response: 0.5, dampingFraction: 0.5)) {
            items.append(item)
        }

        // Auto-remove after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.3)) {
                items.removeAll { $0.id == item.id }
            }
        }
    }
}
