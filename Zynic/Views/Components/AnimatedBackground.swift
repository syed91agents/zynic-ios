import SwiftUI

// MARK: - Pulsing ambient blobs (matches web .bg-glow-blob)
struct AnimatedBackground: View {
    @ObservedObject var colors = ColorManager.shared
    @State private var phase = false

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Blob 1 — top right
            Ellipse()
                .fill(colors.accent.opacity(0.18))
                .frame(width: 320, height: 320)
                .blur(radius: 80)
                .offset(x: phase ? 60 : 80, y: phase ? -160 : -140)
                .animation(.easeInOut(duration: 4).repeatForever(autoreverses: true), value: phase)

            // Blob 2 — bottom left
            Ellipse()
                .fill(colors.accentSecondary.opacity(0.14))
                .frame(width: 280, height: 280)
                .blur(radius: 70)
                .offset(x: phase ? -80 : -60, y: phase ? 200 : 180)
                .animation(.easeInOut(duration: 5).repeatForever(autoreverses: true).delay(1), value: phase)

            // Blob 3 — centre subtle
            Circle()
                .fill(colors.accent.opacity(0.06))
                .frame(width: 200, height: 200)
                .blur(radius: 50)
                .offset(x: phase ? 20 : -20, y: phase ? 40 : -40)
                .animation(.easeInOut(duration: 6).repeatForever(autoreverses: true).delay(2), value: phase)
        }
        .ignoresSafeArea()
        .onAppear { phase = true }
    }
}

// MARK: - Glass card modifier (matches web .glass-panel)
struct GlassMod: ViewModifier {
    @ObservedObject var colors = ColorManager.shared
    var cornerRadius: CGFloat = 20
    var opacity: Double = 0.08

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(colors.accent.opacity(opacity * 0.3))
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(
                            LinearGradient(colors: [
                                colors.accent.opacity(0.3),
                                Color.white.opacity(0.06),
                                colors.accentSecondary.opacity(0.2)
                            ], startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1
                        )
                }
            )
    }
}

extension View {
    func glassCard(cornerRadius: CGFloat = 20, opacity: Double = 0.08) -> some View {
        modifier(GlassMod(cornerRadius: cornerRadius, opacity: opacity))
    }
}

// MARK: - Gradient text
struct GradientText: View {
    let text: String
    var font: Font = .system(size: 32, weight: .black)
    @ObservedObject var colors = ColorManager.shared

    var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(colors.gradient)
    }
}

// MARK: - Pulsing play button glow
struct GlowCircle: View {
    @ObservedObject var colors = ColorManager.shared
    var isPlaying: Bool
    @State private var pulse = false

    var body: some View {
        ZStack {
            // Outer glow ring
            if isPlaying {
                Circle()
                    .stroke(colors.accent.opacity(pulse ? 0.15 : 0.35), lineWidth: 20)
                    .scaleEffect(pulse ? 1.3 : 1.0)
                    .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: pulse)
                    .onAppear { pulse = true }
                    .onDisappear { pulse = false }
            }
            // Inner fill
            Circle()
                .fill(colors.gradient)
                .shadow(color: colors.glowColor, radius: isPlaying ? 20 : 8)
        }
    }
}

// MARK: - Waveform equalizer bars
struct WaveformBars: View {
    @ObservedObject var colors = ColorManager.shared
    var isPlaying: Bool
    var barCount: Int = 5
    @State private var heights: [CGFloat] = [0.4, 0.7, 0.5, 0.9, 0.3]

    var body: some View {
        HStack(spacing: 3) {
            ForEach(0..<barCount, id: \.self) { i in
                RoundedRectangle(cornerRadius: 2)
                    .fill(colors.gradient)
                    .frame(width: 3, height: isPlaying ? heights[i] * 28 : 4)
                    .animation(
                        isPlaying
                            ? .easeInOut(duration: Double.random(in: 0.3...0.6))
                                .repeatForever(autoreverses: true)
                                .delay(Double(i) * 0.08)
                            : .easeOut(duration: 0.3),
                        value: isPlaying
                    )
            }
        }
        .onAppear { randomizeHeights() }
        .onChange(of: isPlaying) { _ in randomizeHeights() }
    }

    private func randomizeHeights() {
        guard isPlaying else { return }
        Timer.scheduledTimer(withTimeInterval: 0.4, repeats: true) { t in
            if !isPlaying { t.invalidate(); return }
            withAnimation { heights = (0..<barCount).map { _ in CGFloat.random(in: 0.25...1.0) } }
        }
    }
}

// MARK: - Vinyl disc view
struct VinylDisc: View {
    @ObservedObject var colors = ColorManager.shared
    var artworkURL: URL?
    var isPlaying: Bool
    @State private var rotation: Double = 0
    @State private var timer: Timer?

    var body: some View {
        ZStack {
            // Vinyl outer ring
            Circle()
                .fill(Color(red: 0.08, green: 0.06, blue: 0.12))
                .shadow(color: colors.glowColor, radius: 24)

            // Grooves
            ForEach([0.48, 0.42, 0.36, 0.30], id: \.self) { r in
                Circle()
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    .scaleEffect(r / 0.5)
            }

            // Album art circle
            ZStack {
                Circle()
                    .fill(colors.gradient)
                    .frame(width: 160, height: 160)

                AsyncImage(url: artworkURL) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .foregroundColor(.white.opacity(0.5))
                }
                .frame(width: 160, height: 160)
                .clipShape(Circle())
            }

            // Centre spindle
            Circle()
                .fill(Color(red: 0.08, green: 0.06, blue: 0.12))
                .frame(width: 24, height: 24)
            Circle()
                .fill(colors.accent)
                .frame(width: 10, height: 10)
        }
        .rotationEffect(.degrees(rotation))
        .onAppear { startSpinning() }
        .onChange(of: isPlaying) { _ in startSpinning() }
        .onDisappear { timer?.invalidate() }
    }

    private func startSpinning() {
        timer?.invalidate()
        guard isPlaying else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 1/60.0, repeats: true) { _ in
            rotation += 0.25
        }
    }
}
