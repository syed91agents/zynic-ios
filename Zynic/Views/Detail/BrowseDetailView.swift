import SwiftUI

struct BrowseDetailView: View {
    let browseId: String
    @ObservedObject var player  = AudioPlayerManager.shared
    @ObservedObject var library = LibraryStore.shared
    @State private var detail: BrowseDetail?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            if isLoading {
                ProgressView().tint(.purple).scaleEffect(1.4)
            } else if let d = detail {
                ScrollView {
                    VStack(spacing: 0) {

                        // ── Centered square artwork (matches Android) ──
                        AsyncImage(url: d.thumbnailURL) { img in
                            img.resizable().scaledToFit()
                        } placeholder: {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(LinearGradient(colors: [.purple.opacity(0.4), .indigo.opacity(0.3)],
                                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                                .overlay(Image(systemName: "music.note.list")
                                    .font(.system(size: 50)).foregroundColor(.white.opacity(0.4)))
                        }
                        .frame(width: 220, height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
                        .padding(.top, 20)
                        .padding(.bottom, 20)

                        // ── Title + subtitle (centered) ─────────────
                        VStack(spacing: 6) {
                            if let title = d.title {
                                Text(title)
                                    .font(.system(size: 24, weight: .black))
                                    .foregroundColor(.white)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                            if let sub = d.subtitle {
                                Text(sub)
                                    .font(.system(size: 13))
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.center)
                                    .lineLimit(2)
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 20)

                        // ── Play / Shuffle ──────────────────────────
                        if let tracks = d.tracks, !tracks.isEmpty {
                            HStack(spacing: 12) {
                                Button {
                                    player.play(tracks: playableTracks(tracks), startAt: 0)
                                } label: {
                                    Label("Play All", systemImage: "play.fill")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.purple)
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .bold))
                                        .clipShape(Capsule())
                                }
                                Button {
                                    player.isShuffled = true
                                    player.play(tracks: playableTracks(tracks).shuffled(), startAt: 0)
                                } label: {
                                    Label("Shuffle", systemImage: "shuffle")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.1))
                                        .foregroundColor(.white)
                                        .font(.system(size: 14, weight: .bold))
                                        .clipShape(Capsule())
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)

                            // ── Track list ─────────────────────────
                            LazyVStack(spacing: 0) {
                                ForEach(Array(tracks.enumerated()), id: \.element.id) { idx, t in
                                    trackRow(t, idx)
                                    if idx < tracks.count - 1 {
                                        Divider()
                                            .background(Color.white.opacity(0.06))
                                            .padding(.leading, 72)
                                    }
                                }
                            }
                        }

                        // ── Related sections ───────────────────────
                        if let sections = d.sections {
                            ForEach(sections) { section in
                                ShelfView(shelf: section) { track, tracks in
                                    let playable = playableTracks(tracks)
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
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: 40)).foregroundColor(.secondary)
                    Text("Could not load").foregroundColor(.secondary)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.clear, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await load() }
    }

    @ViewBuilder
    private func trackRow(_ t: Track, _ idx: Int) -> some View {
        HStack(spacing: 12) {
            Text("\(idx + 1)")
                .font(.system(size: 13))
                .foregroundColor(.secondary)
                .frame(width: 22, alignment: .center)

            AsyncImage(url: t.thumbnailURL) { img in
                img.resizable().scaledToFill()
            } placeholder: { Color.purple.opacity(0.3) }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 2) {
                Text(t.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(player.currentTrack?.id == t.id ? .purple : .white)
                    .lineLimit(1)
                Text(t.displayArtist)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            // Find the tracks list this row belongs to
            if let tracks = detail?.tracks {
                let playable = playableTracks(tracks)
                let pi = playable.firstIndex { $0.id == t.id } ?? 0
                if !playable.isEmpty { player.play(tracks: playable, startAt: pi) }
            }
        }
    }

    private func playableTracks(_ tracks: [Track]) -> [Track] {
        let p = tracks.filter { ($0.videoId != nil && !($0.videoId ?? "").isEmpty) || $0.id.count == 11 }
        return p.isEmpty ? tracks : p
    }

    private func load() async {
        isLoading = true
        do { detail = try await APIClient.shared.browse(browseId) } catch {}
        isLoading = false
    }
}
