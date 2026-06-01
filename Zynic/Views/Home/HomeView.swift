import SwiftUI

struct HomeView: View {
    @ObservedObject var player = AudioPlayerManager.shared
    @ObservedObject var colors = ColorManager.shared
    @State private var shelves: [Shelf] = []
    @State private var isLoading = true
    @State private var error: String?
    @State private var selectedBrowseId: String?

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground()

                if isLoading {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(colors.gradient).frame(width: 60, height: 60)
                                .shadow(color: colors.glowColor, radius: 16)
                            ProgressView().tint(.white)
                        }
                        Text("Loading your music…")
                            .foregroundColor(.secondary)
                            .font(.system(size: 14))
                    }
                } else if let err = error {
                    VStack(spacing: 16) {
                        Image(systemName: "wifi.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundStyle(colors.gradient)
                        Text(err).foregroundColor(.secondary).multilineTextAlignment(.center)
                        Button("Retry") { Task { await load() } }
                            .buttonStyle(.borderedProminent).tint(colors.accent)
                    }.padding()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 36) {
                            // ── Hero header ──────────────────
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(greeting())
                                        .font(.system(size: 15)).foregroundColor(.secondary)
                                    GradientText(text: "Zynic", font: .system(size: 36, weight: .black))
                                }
                                Spacer()
                                // Animated logo icon
                                ZStack {
                                    Circle()
                                        .fill(colors.gradient)
                                        .frame(width: 44, height: 44)
                                        .shadow(color: colors.glowColor, radius: 12)
                                    Image(systemName: "music.note.house.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.white)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)

                            // Now playing pill (if active)
                            if let t = player.currentTrack {
                                HStack(spacing: 12) {
                                    AsyncImage(url: t.thumbnailURL) { img in
                                        img.resizable().scaledToFill()
                                    } placeholder: { colors.accent.opacity(0.3) }
                                    .frame(width: 36, height: 36)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))

                                    VStack(alignment: .leading, spacing: 1) {
                                        Text("Now Playing").font(.system(size: 10)).foregroundColor(.secondary)
                                        Text(t.title).font(.system(size: 13, weight: .bold)).foregroundColor(.white).lineLimit(1)
                                    }
                                    Spacer()
                                    WaveformBars(isPlaying: player.isPlaying, barCount: 4)
                                        .frame(height: 18)
                                }
                                .padding(.horizontal, 14).padding(.vertical, 10)
                                .glassCard(cornerRadius: 16)
                                .padding(.horizontal)
                                .transition(.move(edge: .top).combined(with: .opacity))
                            }

                            // Shelves
                            ForEach(shelves) { shelf in
                                ShelfView(shelf: shelf) { track, tracks in
                                    handleTap(track: track, tracks: tracks)
                                }
                            }

                            Spacer(minLength: 120)
                        }
                    }
                    .refreshable { await load() }
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(isPresented: Binding(
                get: { selectedBrowseId != nil },
                set: { if !$0 { selectedBrowseId = nil } }
            )) {
                if let bid = selectedBrowseId { BrowseDetailView(browseId: bid) }
            }
        }
        .task { await load() }
    }

    private func handleTap(track: Track, tracks: [Track]) {
        if let vid = track.videoId, !vid.isEmpty {
            let playable = tracks.filter { !($0.videoId ?? "").isEmpty }
            let idx = playable.firstIndex { $0.id == track.id } ?? 0
            player.play(tracks: playable.isEmpty ? [track] : playable, startAt: idx)
        } else if let bid = track.browseId, !bid.isEmpty {
            selectedBrowseId = bid
        } else if track.id.count == 11 {
            player.play(track)
        } else {
            selectedBrowseId = track.id
        }
    }

    private func load() async {
        isLoading = true; error = nil
        do { shelves = try await APIClient.shared.fetchHome() }
        catch { self.error = "Could not load.\nCheck your connection." }
        isLoading = false
    }

    private func greeting() -> String {
        switch Calendar.current.component(.hour, from: Date()) {
        case 5..<12:  return "Good morning ☀️"
        case 12..<17: return "Good afternoon 🎵"
        case 17..<21: return "Good evening 🌆"
        default:      return "Good night 🌙"
        }
    }
}
