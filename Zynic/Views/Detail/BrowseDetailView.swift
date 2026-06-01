import SwiftUI

struct BrowseDetailView: View {
    let browseId: String
    @ObservedObject var player = AudioPlayerManager.shared
    @ObservedObject var library = LibraryStore.shared
    @State private var detail: BrowseDetail?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if isLoading {
                ProgressView().tint(.purple).scaleEffect(1.5)
            } else if let d = detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        ZStack(alignment: .bottom) {
                            AsyncImage(url: d.thumbnailURL) { img in
                                img.resizable().scaledToFill()
                            } placeholder: {
                                LinearGradient(colors: [.purple.opacity(0.5), .black],
                                               startPoint: .top, endPoint: .bottom)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 280)
                            .clipped()

                            LinearGradient(colors: [.clear, .black],
                                           startPoint: .top, endPoint: .bottom)
                            .frame(height: 150)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(d.title ?? "")
                                    .font(.system(size: 24, weight: .black))
                                    .foregroundColor(.white)
                                if let sub = d.subtitle {
                                    Text(sub)
                                        .font(.system(size: 13))
                                        .foregroundColor(.secondary)
                                }
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding()
                        }

                        // Play / Shuffle row
                        if let tracks = d.tracks, !tracks.isEmpty {
                            HStack(spacing: 12) {
                                Button {
                                    player.play(tracks: tracks, startAt: 0)
                                } label: {
                                    Label("Play", systemImage: "play.fill")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.purple)
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .foregroundColor(.white)
                                        .font(.system(size: 15, weight: .bold))
                                }

                                Button {
                                    player.isShuffled = true
                                    player.play(tracks: tracks.shuffled(), startAt: 0)
                                } label: {
                                    Label("Shuffle", systemImage: "shuffle")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color.white.opacity(0.1))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                        .foregroundColor(.white)
                                        .font(.system(size: 15, weight: .bold))
                                }
                            }
                            .padding()

                            // Track list
                            LazyVStack(spacing: 0) {
                                ForEach(Array(tracks.enumerated()), id: \.element.id) { idx, t in
                                    TrackRowView(track: t, index: idx + 1) {
                                        let playable = tracks.filter { ($0.videoId != nil && !($0.videoId ?? "").isEmpty) || $0.id.count == 11 }
                                        let pi = playable.firstIndex(where: { $0.id == t.id }) ?? idx
                                        if !playable.isEmpty {
                                            player.play(tracks: playable, startAt: pi)
                                        }
                                    }
                                    .padding(.horizontal)
                                    if idx < tracks.count - 1 {
                                        Divider().background(Color.white.opacity(0.06)).padding(.leading, 80)
                                    }
                                }
                            }
                        }

                        // Sections (artist pages etc.)
                        if let sections = d.sections {
                            ForEach(sections) { section in
                                ShelfView(shelf: section) { track, tracks in
                                    if let idx = tracks.firstIndex(where: { $0.id == track.id }) {
                                        player.play(tracks: tracks, startAt: idx)
                                    }
                                }
                                .padding(.top, 24)
                            }
                        }

                        Spacer(minLength: 100)
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        do { detail = try await APIClient.shared.browse(browseId) } catch {}
        isLoading = false
    }
}
