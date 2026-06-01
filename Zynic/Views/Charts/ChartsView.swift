import SwiftUI

struct ChartsView: View {
    @ObservedObject var player = AudioPlayerManager.shared
    @ObservedObject var colors = ColorManager.shared
    @State private var charts: [Shelf] = []
    @State private var isLoading = true

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedBackground()
                if isLoading {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle().fill(colors.gradient).frame(width: 56, height: 56)
                            ProgressView().tint(.white)
                        }
                        Text("Loading charts…").foregroundColor(.secondary)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 32) {
                            ForEach(charts) { shelf in
                                VStack(alignment: .leading, spacing: 0) {
                                    HStack {
                                        Text(shelf.title)
                                            .font(.system(size: 19, weight: .black))
                                            .foregroundColor(.white)
                                        Spacer()
                                        Button("Play All") {
                                            let playable = shelf.items.filter {
                                                ($0.videoId != nil && !($0.videoId ?? "").isEmpty) || $0.id.count == 11
                                            }
                                            player.play(tracks: playable.isEmpty ? shelf.items : playable, startAt: 0)
                                        }
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(colors.gradient)
                                    }
                                    .padding(.horizontal)
                                    .padding(.bottom, 12)

                                    LazyVStack(spacing: 0) {
                                        ForEach(Array(shelf.items.enumerated()), id: \.element.id) { idx, t in
                                            TrackRowView(track: t, index: idx + 1) {
                                                let playable = shelf.items.filter {
                                                    ($0.videoId != nil && !($0.videoId ?? "").isEmpty) || $0.id.count == 11
                                                }
                                                let pi = playable.firstIndex { $0.id == t.id } ?? idx
                                                player.play(tracks: playable.isEmpty ? shelf.items : playable, startAt: pi)
                                            }
                                            .padding(.horizontal)
                                            if idx < shelf.items.count - 1 {
                                                Divider().background(Color.white.opacity(0.06))
                                                    .padding(.leading, 74)
                                            }
                                        }
                                    }
                                    .glassCard(cornerRadius: 16)
                                    .padding(.horizontal)
                                }
                            }
                            Spacer(minLength: 120)
                        }
                        .padding(.top)
                    }
                    .refreshable { await load() }
                }
            }
            .navigationTitle("Charts 🔥")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.clear, for: .navigationBar)
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
