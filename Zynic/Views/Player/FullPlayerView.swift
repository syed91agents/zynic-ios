import SwiftUI

struct FullPlayerView: View {
    @ObservedObject var player  = AudioPlayerManager.shared
    @ObservedObject var library = LibraryStore.shared
    @ObservedObject var colors  = ColorManager.shared
    @Binding var isPresented: Bool

    @State private var showLyrics  = false
    @State private var isDragging  = false
    @State private var dragProgress: Double = 0
    @State private var artScale: CGFloat = 1.0
    @State private var showQueue   = false

    var displayProgress: Double { isDragging ? dragProgress : player.progress }

    var body: some View {
        ZStack {
            // Dynamic blurred artwork background
            ZStack {
                Color.black
                AsyncImage(url: player.currentTrack?.thumbnailURL) { img in
                    img.resizable().scaledToFill()
                        .blur(radius: 80).opacity(0.55).saturation(1.8)
                } placeholder: { Color.clear }
                LinearGradient(
                    colors: [colors.accent.opacity(0.25), Color.black.opacity(0.85), Color.black],
                    startPoint: .top, endPoint: .bottom)
            }
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Top bar ──────────────────────────────
                HStack {
                    Button { isPresented = false } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .glassCard(cornerRadius: 12)
                    }

                    Spacer()

                    VStack(spacing: 2) {
                        Text("NOW PLAYING")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .tracking(2)
                        Text(player.currentTrack?.title ?? "")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                    }

                    Spacer()

                    Button {
                        if let t = player.currentTrack {
                            library.contains(t) ? library.remove(t) : library.add(t)
                        }
                    } label: {
                        Image(systemName: (player.currentTrack.map { library.contains($0) } ?? false) ? "heart.fill" : "heart")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor((player.currentTrack.map { library.contains($0) } ?? false) ? .pink : .white)
                            .frame(width: 40, height: 40)
                            .glassCard(cornerRadius: 12)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)

                if showLyrics {
                    LyricsView()
                        .frame(maxHeight: .infinity)
                } else if showQueue {
                    QueueView()
                        .frame(maxHeight: .infinity)
                } else {
                    Spacer()

                    // ── Vinyl disc artwork ────────────────
                    VinylDisc(
                        artworkURL: player.currentTrack?.thumbnailURL,
                        isPlaying: player.isPlaying
                    )
                    .frame(width: 270, height: 270)
                    .scaleEffect(player.isPlaying ? 1.0 : 0.88)
                    .animation(.spring(response: 0.5, dampingFraction: 0.7), value: player.isPlaying)
                    .shadow(color: colors.glowColor, radius: player.isPlaying ? 40 : 10)

                    Spacer()
                }

                // ── Track info ───────────────────────────
                VStack(spacing: 4) {
                    Text(player.currentTrack?.title ?? "Nothing Playing")
                        .font(.system(size: 22, weight: .black))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .padding(.horizontal, 24)

                    Text(player.currentTrack?.displayArtist ?? "—")
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                }
                .padding(.bottom, 20)

                // ── Progress bar ─────────────────────────
                VStack(spacing: 6) {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                                .frame(height: 4)

                            Capsule()
                                .fill(colors.gradient)
                                .frame(width: max(0, geo.size.width * displayProgress), height: 4)

                            Circle()
                                .fill(Color.white)
                                .frame(width: 14, height: 14)
                                .shadow(color: colors.glowColor, radius: 6)
                                .offset(x: max(0, geo.size.width * displayProgress - 7))
                        }
                        .gesture(DragGesture(minimumDistance: 0).onChanged { v in
                            isDragging = true
                            dragProgress = max(0, min(1, v.location.x / geo.size.width))
                        }.onEnded { _ in
                            player.seek(to: dragProgress); isDragging = false
                        })
                    }
                    .frame(height: 14)

                    HStack {
                        Text(fmt(player.currentTime))
                        Spacer()
                        Text(fmt(player.duration))
                    }
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.secondary)
                }
                .padding(.horizontal, 24)

                // ── Main controls ────────────────────────
                HStack(spacing: 40) {
                    Button { player.toggleShuffle() } label: {
                        Image(systemName: "shuffle")
                            .font(.system(size: 20))
                            .foregroundStyle(player.isShuffled ? AnyShapeStyle(colors.gradient) : AnyShapeStyle(Color.white.opacity(0.6)))
                    }

                    Button { player.previous() } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }

                    // Big play/pause with glow
                    ZStack {
                        GlowCircle(isPlaying: player.isPlaying)
                            .frame(width: 72, height: 72)

                        Button { player.togglePlayPause() } label: {
                            ZStack {
                                if player.isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                        .font(.system(size: 26))
                                        .foregroundColor(.white)
                                }
                            }
                        }
                    }
                    .frame(width: 72, height: 72)

                    Button { player.next() } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                    }

                    Button { player.cycleRepeat() } label: {
                        Image(systemName: player.repeatMode == .one ? "repeat.1" : "repeat")
                            .font(.system(size: 20))
                            .foregroundStyle(player.repeatMode != .none ? AnyShapeStyle(colors.gradient) : AnyShapeStyle(Color.white.opacity(0.6)))
                    }
                }
                .padding(.top, 20)

                // ── Volume ───────────────────────────────
                HStack(spacing: 10) {
                    Image(systemName: "speaker.fill")
                        .foregroundColor(.secondary).font(.system(size: 12))
                    Slider(value: Binding(
                        get: { Double(player.volume) },
                        set: { player.setVolume(Float($0)) }
                    ))
                    .tint(colors.accent)
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.secondary).font(.system(size: 12))
                }
                .padding(.horizontal, 28)
                .padding(.top, 16)

                // ── Bottom action row ─────────────────────
                HStack(spacing: 20) {
                    Spacer()
                    // Lyrics
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showLyrics.toggle(); showQueue = false
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: "text.quote")
                                .font(.system(size: 18))
                            Text("Lyrics").font(.system(size: 10))
                        }
                        .foregroundStyle(showLyrics ? AnyShapeStyle(colors.gradient) : AnyShapeStyle(Color.white.opacity(0.5)))
                        .frame(width: 60, height: 48)
                        .glassCard(cornerRadius: 14)
                    }

                    // Waveform / EQ indicator
                    VStack(spacing: 3) {
                        WaveformBars(isPlaying: player.isPlaying, barCount: 5)
                            .frame(height: 22)
                        Text("Live").font(.system(size: 10)).foregroundColor(.secondary)
                    }
                    .frame(width: 60, height: 48)
                    .glassCard(cornerRadius: 14)

                    // Queue
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            showQueue.toggle(); showLyrics = false
                        }
                    } label: {
                        VStack(spacing: 3) {
                            Image(systemName: "list.bullet.below.rectangle")
                                .font(.system(size: 18))
                            Text("Queue").font(.system(size: 10))
                        }
                        .foregroundStyle(showQueue ? AnyShapeStyle(colors.gradient) : AnyShapeStyle(Color.white.opacity(0.5)))
                        .frame(width: 60, height: 48)
                        .glassCard(cornerRadius: 14)
                    }
                    Spacer()
                }
                .padding(.top, 16)

                Spacer(minLength: 28)
            }
        }
    }

    func fmt(_ s: Double) -> String {
        guard s.isFinite, s > 0 else { return "0:00" }
        return String(format: "%d:%02d", Int(s)/60, Int(s)%60)
    }
}

// MARK: - Queue view
struct QueueView: View {
    @ObservedObject var player = AudioPlayerManager.shared
    @ObservedObject var colors = ColorManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("Up Next")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text("\(player.queue.count) tracks")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(player.queue.enumerated()), id: \.element.id) { idx, t in
                        HStack(spacing: 12) {
                            if idx == player.queueIndex {
                                WaveformBars(isPlaying: player.isPlaying, barCount: 3)
                                    .frame(width: 20, height: 20)
                            } else {
                                Text("\(idx + 1)")
                                    .font(.system(size: 12))
                                    .foregroundColor(.secondary)
                                    .frame(width: 20)
                            }

                            AsyncImage(url: t.thumbnailURL) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                colors.accent.opacity(0.3)
                            }
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 6))

                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.title)
                                    .font(.system(size: 14, weight: idx == player.queueIndex ? .bold : .regular))
                                    .foregroundColor(idx == player.queueIndex ? colors.accent : .white)
                                    .lineLimit(1)
                                Text(t.displayArtist)
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(idx == player.queueIndex ? colors.accent.opacity(0.1) : Color.clear)
                        .onTapGesture {
                            player.play(tracks: player.queue, startAt: idx)
                        }
                    }
                }
            }
        }
    }
}
