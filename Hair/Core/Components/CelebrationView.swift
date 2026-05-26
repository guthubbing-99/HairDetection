import SwiftUI

struct CelebrationView: View {
    @Binding var isActive: Bool
    let tintColor: Color

    @State private var particles: [CelebrationParticle] = []
    @State private var timer: Timer?

    private let emojis = ["✨", "💫", "⭐", "🌟", "💖", "🎉", "🔥", "💪"]

    var body: some View {
        ZStack {
            ForEach(particles) { particle in
                Text(particle.emoji)
                    .font(.system(size: particle.size))
                    .scaleEffect(particle.scale)
                    .rotationEffect(.degrees(particle.rotation))
                    .position(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
            }
        }
        .allowsHitTesting(false)
        .onChange(of: isActive) { _, active in
            if active { burst() }
        }
    }

    private func burst() {
        let centerX = UIScreen.main.bounds.width / 2
        let centerY = UIScreen.main.bounds.height / 2

        for i in 0..<20 {
            let angle = Double(i) * (360.0 / 20.0) + Double.random(in: -10...10)
            let distance = CGFloat.random(in: 60...180)
            let rad = angle * .pi / 180

            let particle = CelebrationParticle(
                emoji: emojis.randomElement()!,
                x: centerX,
                y: centerY,
                targetX: centerX + cos(rad) * distance,
                targetY: centerY + sin(rad) * distance,
                size: CGFloat.random(in: 20...40),
                rotation: Double.random(in: 0...360)
            )
            particles.append(particle)

            withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
                if let idx = particles.firstIndex(where: { $0.id == particle.id }) {
                    particles[idx].x = particle.targetX
                    particles[idx].y = particle.targetY
                    particles[idx].scale = CGFloat.random(in: 0.3...1.2)
                    particles[idx].opacity = 1.0
                }
            }
        }

        // Fade out and cleanup
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.4)) {
                for i in particles.indices {
                    particles[i].opacity = 0
                }
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
            particles.removeAll()
            isActive = false
        }
    }
}

struct CelebrationParticle: Identifiable {
    let id = UUID()
    let emoji: String
    var x: CGFloat
    var y: CGFloat
    let targetX: CGFloat
    let targetY: CGFloat
    var size: CGFloat
    var scale: CGFloat = 0.1
    var opacity: Double = 0
    var rotation: Double
}
