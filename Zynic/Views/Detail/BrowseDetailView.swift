import SwiftUI

struct BrowseDetailView: View {
    let browseId: String
    @ObservedObject var player  = AudioPlayerManager.shared
    @ObservedObject var library = LibraryStore.shared
    @ObservedObject var colors  = ColorManager.shared
    @State private var detail: BrowseDetail?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            // Dynamic background from album art
            ZStack {
                Color.black
                if let thumb = detail?.thumbnail, let url = URL(string: thumb) {
                    AsyncImage(url: url) { img in
                        img.resizable().scaledToFill()
                            .blur(radius: 60).opacity(0.35).saturation(1.5)
                    } placeholder: { Color.clear }
                    LinearGradient(colors: [colors.accent.opacity(0.15), .black.opacity(0.9)],
                                   startPoint: .top, endPoint: .bottom)
                }
            }
            .ignoresSafeArea()

            if isLoading {
                VStack(spacing: 16) {
                    ZStack {
                        Circle().fill(colors.gradient).frame(width: 56, height: 56)
                            .shadow(color: colors.glowColor, radius: 12)
                        ProgressView().tint(.white)
                    }
                    Text("Loading…").foregroundColor(.secondary).font(.system(size: 13))
                }
            } else if let d = detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // ── Header ──────────────────────────────────
                        ZStack(alignment: .bottom) {
                            AsyncImage(url: d.thumbnailURL) { img in
                                img.resizable().scaledToFill()
                            } placeholder: { colors.gradient }
                            .frame(maxWidth: .infinity).frame(height: 300).clipped()

                            LinearGradient(colors: [.clear, .black],
                                           startPoint: .top, endPoint: .bottom)
                            .frame(height: 200)

                            VStack(alignment: .leading, spacing: 6) {
                                if let title = d.title {
                                    Text(title)
                                        .font(.system(size: 26, weight: .black))
                                        .foregroundColor(.white)
                                }
                                if let sub = d.subtitle {
                                    Text(sub).font(.system(size: 13)).foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        }

                        // ── Actions ──────────────────────────────────
                        if let tracks = d.tracks, !tracks.isEmpty {
                            HStack(spacing: 12) {
                                Button {
                                    let playable = tracks.filter { ($0.videoId != nil && !($0.videoId ?? "").isEmpty) || $0.id.count == 11 }
                                    player.play(tracks: playable.isEmpty ? tracks : playable, startAt: 0)
                                } label: {
                                    Label("Play All", systemImage: "play.fill")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 13)
                                        .background(colors.gradient)
                                        .foregroundColor(.white)
                                        .font(.system(size: 15, weight: .bold))
                                        .clipShape(RoundedRectangle(cornerRadius: 14))
                                        .shadow(color: colors.glowColor, radius: 8)
                                }

                                Button {
                                    let playable = tracks.filter { ($0.videoId != nil && !($0.videoId ?? "").isEmpty) || $0.id.count == 11 }
                                    player.isShuffled = true
                                    player.play(tracks: (playable.isEmpty ? tracks : playable).shuffled(), startAt: 0)
                                } label: {
                                    Label("Shuffle", systemImage: "shuffle")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 13)
                                        .glassCard(cornerRadius: 14)
                                        .foregroundColor(.white)
                                        .font(.system(size: 15, weight: .bold))
                                }
                            }
                            .padding()

                            // ── Track list ─────────────────────────────
                            LazyVStack(spacing: 0) {
                                ForEach(Array(tracks.enumerated()), id: \.element.id) { idx, t in
                                    TrackRowView(track: t, index: idx + 1) {
                                        let playable = tracks.filter { ($0.videoId != nil && !($0.videoId ?? "").isEmpty) || $0.id.count == 11 }
                                        let pi = playable.firstIndex { $0.id == t.id } ?? idx
                                        if !playable.isEmpty { player.play(tracks: playable, startAt: pi) }
                                    }
                                    .padding(.horizontal)
                                    if idx < tracks.count - 1 {
                                        Divider()
                                            .background(Color.white.opacity(0.06))
                                            .padding(.leading, 74)
                                    }
                                }
                            }
                        }

                        // ── Related sections ────────────────────────
                        if let sections = d.sections {
                            ForEach(sections) { section in
                                ShelfView(shelf: section) { track, tracks in
                                    let playable = tracks.filter { ($0.videoId != nil && !($0.videoId ?? "").isEmpty) || $0.id.count == 11 }
                                    if let idx = playable.firstIndex(where: { $0.id == track.id }) {
                                        player.play(tracks: playable, startAt: idx)
                                    }
                                }
                                .padding(.top, 24)
                            }
                        }

                        Spacer(minLength: 120)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if let t = detail?.tracks?.first {
                    Button {
                        library.contains(t) ? library.remove(t) : library.add(t)
                    } label: {
                        Image(systemName: library.contains(t) ? "heart.fill" : "heart")
                            .foregroundColor(library.contains(t) ? .pink : .white)
                    }
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        do {
            detail = try await APIClient.shared.browse(browseId)
            // Extract color from album art
            if let thumb = detail?.thumbnail {
                colors.updateFromURL(thumb)
            }
        } catch {}
        isLoading = false
    }
}
