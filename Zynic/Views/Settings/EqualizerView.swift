import SwiftUI

struct EqualizerView: View {
    @ObservedObject var player = AudioPlayerManager.shared
    @State private var gains: [Float] = [0, 0, 0, 0, 0]
    @State private var selectedPreset = "Flat"

    let bands = ["60 Hz", "230 Hz", "910 Hz", "4 kHz", "14 kHz"]
    let presets: [String: [Float]] = [
        "Flat":       [0,   0,   0,   0,   0  ],
        "Bass Boost": [8,   5,   0,  -1,  -2  ],
        "Treble":     [-2, -1,   0,   5,   8  ],
        "Vocal":      [-2,  0,   4,   4,   0  ],
        "Electronic": [7,   4,  -1,   3,   6  ],
        "Pop":        [-1,  3,   5,   3,  -1  ],
        "Rock":       [5,   3,  -1,   3,   5  ],
        "Classical":  [5,   3,   0,   3,   5  ],
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                ScrollView {
                    VStack(spacing: 28) {

                        // Presets
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Presets")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    ForEach(Array(presets.keys.sorted()), id: \.self) { name in
                                        Button(name) {
                                            selectedPreset = name
                                            applyPreset(name)
                                        }
                                        .font(.system(size: 13, weight: .semibold))
                                        .padding(.horizontal, 16)
                                        .padding(.vertical, 8)
                                        .background(selectedPreset == name ? Color.purple : Color.white.opacity(0.08))
                                        .foregroundColor(selectedPreset == name ? .white : .secondary)
                                        .clipShape(Capsule())
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }

                        // EQ Sliders
                        VStack(spacing: 20) {
                            Text("Custom")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal)

                            HStack(alignment: .bottom, spacing: 0) {
                                ForEach(0..<5) { i in
                                    VStack(spacing: 8) {
                                        Text(gains[i] > 0 ? "+\(Int(gains[i]))" : "\(Int(gains[i]))")
                                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                                            .foregroundColor(gains[i] == 0 ? .secondary : .purple)
                                            .frame(height: 18)

                                        VerticalSlider(value: $gains[i], range: -12...12) { v in
                                            player.setEQGain(v, band: i)
                                            selectedPreset = "Custom"
                                        }
                                        .frame(height: 180)

                                        Text(bands[i])
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                            }
                            .padding(.horizontal, 16)
                        }

                        // Reset
                        Button("Reset to Flat") {
                            selectedPreset = "Flat"
                            applyPreset("Flat")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.purple)
                        .padding(.top, 4)

                        Spacer(minLength: 40)
                    }
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Equalizer")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func applyPreset(_ name: String) {
        guard let preset = presets[name] else { return }
        withAnimation(.spring(response: 0.4)) { gains = preset }
        for (i, g) in preset.enumerated() { player.setEQGain(g, band: i) }
    }
}

// MARK: - Vertical Slider
struct VerticalSlider: View {
    @Binding var value: Float
    let range: ClosedRange<Float>
    var onChange: ((Float) -> Void)?

    var body: some View {
        GeometryReader { geo in
            let h = geo.size.height
            let fraction = CGFloat((value - range.lowerBound) / (range.upperBound - range.lowerBound))
            let thumbY   = h - fraction * h

            ZStack(alignment: .bottom) {
                // Track
                Capsule()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 4)
                    .frame(maxWidth: .infinity)

                // Fill
                Capsule()
                    .fill(LinearGradient(colors: [.purple, .indigo], startPoint: .bottom, endPoint: .top))
                    .frame(width: 4, height: fraction * h)
                    .frame(maxWidth: .infinity)

                // Zero line
                Rectangle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 14, height: 1)
                    .offset(y: -(h * 0.5 - 0))
                    .frame(maxWidth: .infinity)

                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: 18, height: 18)
                    .shadow(color: .purple.opacity(0.5), radius: 4)
                    .frame(maxWidth: .infinity)
                    .offset(y: -(fraction * h))
            }
            .frame(width: geo.size.width, height: h)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let newFrac = max(0, min(1, 1 - (drag.location.y / h)))
                        let newVal  = Float(newFrac) * (range.upperBound - range.lowerBound) + range.lowerBound
                        value = newVal
                        onChange?(newVal)
                    }
            )
        }
    }
}
