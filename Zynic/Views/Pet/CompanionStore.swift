import SwiftUI

// MARK: - Active companion shared across the app
final class CompanionStore: ObservableObject {
    static let shared = CompanionStore()

    @Published var activePet: PetEntry?
    @Published var showFloating = true

    private init() { load() }

    func setActive(_ pet: PetEntry?) {
        activePet = pet
        save()
    }

    func toggleFloating() {
        showFloating.toggle()
        UserDefaults.standard.set(showFloating, forKey: "zynic_show_floating_pet")
    }

    private func save() {
        if let pet = activePet, let data = try? JSONEncoder().encode(pet) {
            UserDefaults.standard.set(data, forKey: "zynic_active_pet")
        } else {
            UserDefaults.standard.removeObject(forKey: "zynic_active_pet")
        }
    }

    private func load() {
        showFloating = UserDefaults.standard.object(forKey: "zynic_show_floating_pet") as? Bool ?? true
        if let data = UserDefaults.standard.data(forKey: "zynic_active_pet"),
           let pet = try? JSONDecoder().decode(PetEntry.self, from: data) {
            activePet = pet
        }
    }
}

// MARK: - Floating draggable companion overlay
struct FloatingCompanion: View {
    @ObservedObject var companion = CompanionStore.shared
    @ObservedObject var player    = AudioPlayerManager.shared

    @State private var position = CGPoint(x: 80, y: 400)
    @State private var dragOffset = CGSize.zero
    @State private var anim: SpriteAnim = .idle
    @State private var facingLeft = false
    @State private var isDragging = false
    @State private var showBubble = false
    @State private var bubbleText = ""
    @State private var wanderTimer: Timer?

    let petSize: CGFloat = 96

    var body: some View {
        GeometryReader { geo in
            if let pet = companion.activePet, companion.showFloating {
                ZStack(alignment: .topLeading) {
                    // Speech bubble
                    if showBubble {
                        Text(bubbleText)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 10).padding(.vertical, 6)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.purple.opacity(0.9))
                            )
                            .fixedSize()
                            .position(x: position.x + dragOffset.width,
                                      y: position.y + dragOffset.height - petSize/2 - 16)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // The animated sprite
                    AnimatedSpriteView(
                        spritesheetUrl: pet.spritesheetUrl,
                        anim: anim,
                        size: petSize,
                        fps: isDragging ? 12 : 8
                    )
                    .scaleEffect(x: facingLeft ? -1 : 1, y: 1)  // flip horizontally
                    .scaleEffect(isDragging ? 1.15 : 1.0)
                    .shadow(color: .black.opacity(0.4), radius: 8, y: 6)
                    .position(x: position.x + dragOffset.width,
                              y: position.y + dragOffset.height)
                    .gesture(
                        DragGesture()
                            .onChanged { v in
                                isDragging = true
                                dragOffset = v.translation
                                anim = .running
                                facingLeft = v.translation.width < 0
                                stopWandering()
                            }
                            .onEnded { v in
                                position.x += v.translation.width
                                position.y += v.translation.height
                                dragOffset = .zero
                                isDragging = false
                                // Clamp to screen
                                position.x = min(max(petSize/2, position.x), geo.size.width - petSize/2)
                                position.y = min(max(120, position.y), geo.size.height - 160)
                                anim = .idle
                                bubble("Wheee! 🎵")
                                startWandering(in: geo.size)
                            }
                    )
                    .onTapGesture {
                        anim = .jumping
                        bubble(randomPhrase())
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                            anim = .idle
                        }
                    }
                }
                .onAppear {
                    position = CGPoint(x: 70, y: geo.size.height - 200)
                    startWandering(in: geo.size)
                }
                .onDisappear { stopWandering() }
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(companion.activePet != nil && companion.showFloating)
    }

    // MARK: - Wandering AI
    private func startWandering(in size: CGSize) {
        stopWandering()
        wanderTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { _ in
            guard !isDragging else { return }
            let action = Int.random(in: 0...3)
            switch action {
            case 0:  // walk somewhere
                let target = CGPoint(
                    x: CGFloat.random(in: petSize...(size.width - petSize)),
                    y: CGFloat.random(in: 140...(size.height - 180))
                )
                facingLeft = target.x < position.x
                anim = facingLeft ? .runningLeft : .runningRight
                withAnimation(.easeInOut(duration: 2.5)) {
                    position = target
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    if !isDragging { anim = .idle }
                }
            case 1:  anim = .waving
                     DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { if !isDragging { anim = .idle } }
            case 2:  anim = .jumping
                     DispatchQueue.main.asyncAfter(deadline: .now() + 1) { if !isDragging { anim = .idle } }
            default: anim = player.isPlaying ? .running : .idle
            }
        }
    }

    private func stopWandering() { wanderTimer?.invalidate(); wanderTimer = nil }

    private func bubble(_ text: String) {
        bubbleText = text
        withAnimation(.spring()) { showBubble = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showBubble = false }
        }
    }

    private func randomPhrase() -> String {
        let phrases = ["Hi there! 👋", "Love this song! 🎶", "Boop! ✨",
                       "Keep vibing! 🌟", "I'm dancing! 💃", "Yay music! 🎵"]
        return phrases.randomElement() ?? "Hi!"
    }
}
