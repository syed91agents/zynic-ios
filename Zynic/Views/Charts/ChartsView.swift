import SwiftUI

struct ChartsView: View {
    @ObservedObject var player = AudioPlayerManager.shared
    @State private var charts: [Shelf] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if isLoading {
                    ProgressView().tint(.purple).scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(spacing: 32) {
                            ForEach(charts) { shelf in
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack {
                                        Text(shelf.title)
                                            .font(.system(size: 18, weight: .bold))
                                        Spacer()
                                        Button("Play All") {
                                            player.play(tracks: shelf.items, startAt: 0)
                                        }
                                        .font(.system(size: 13))
                                        .foregroundColor(.purple)
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 10)

                                    LazyVStack(spacing: 0) {
                                        ForEach(Array(shelf.items.enumerated()), id: \.element.id) { idx, t in
                                            TrackRowView(track: t, index: idx + 1) {
                                                let playable = shelf.items.filter { ($0.videoId ?? $0.id).count == 11 }
                                                let pi = playable.firstIndex(where: { $0.id == t.id }) ?? idx
                                                player.play(tracks: playable.isEmpty ? shelf.items : playable, startAt: pi)
                                            }
                                            .padding(.horizontal)
                                            if idx < shelf.items.count - 1 {
                                                Divider().background(Color.white.opacity(0.06)).padding(.leading, 80)
                                            }
                                        }
                                    }
                                }
                            }
                            Spacer(minLength: 100)
                        }
                        .padding(.top)
                    }
                    .refreshable { await load() }
                }
            }
            .navigationTitle("Charts 🔥")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        do { charts = try await APIClient.shared.fetchCharts() } catch {}
        isLoading = false
    }
}
