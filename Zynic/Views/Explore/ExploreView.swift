import SwiftUI

struct ExploreView: View {
    @ObservedObject var player = AudioPlayerManager.shared
    @State private var newReleases: [Track] = []
    @State private var moodsGenres: [Track] = []
    @State private var isLoading = true
    @State private var selectedBrowse: String?
    @State private var browseDetail: BrowseDetail?
    @State private var showingDetail = false

    let moodColors: [Color] = [.purple, .indigo, .pink, .orange, .teal, .blue, .green, .red]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if isLoading {
                    ProgressView().tint(.purple).scaleEffect(1.5)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 32) {

                            // New Releases
                            if !newReleases.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("New Releases")
                                        .font(.system(size: 18, weight: .bold))
                                        .padding(.horizontal)
                                    ScrollView(.horizontal, showsIndicators: false) {
                                        HStack(alignment: .top, spacing: 16) {
                                            ForEach(newReleases) { t in
                                                MusicCardView(track: t, onTap: {
                                                    if let bid = t.browseId {
                                                        selectedBrowse = bid
                                                    } else {
                                                        player.play(t)
                                                    }
                                                }, width: 140)
                                            }
                                        }.padding(.horizontal)
                                    }
                                }
                            }

                            // Moods & Genres
                            if !moodsGenres.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Moods & Genres")
                                        .font(.system(size: 18, weight: .bold))
                                        .padding(.horizontal)
                                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                        ForEach(Array(moodsGenres.enumerated()), id: \.element.id) { idx, t in
                                            Button {
                                                selectedBrowse = t.id
                                            } label: {
                                                ZStack {
                                                    moodColors[idx % moodColors.count].opacity(0.3)
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .stroke(moodColors[idx % moodColors.count].opacity(0.5), lineWidth: 1)
                                                    Text(t.title)
                                                        .font(.system(size: 15, weight: .bold))
                                                        .foregroundColor(.white)
                                                        .multilineTextAlignment(.center)
                                                        .padding(8)
                                                }
                                                .frame(height: 80)
                                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                    .padding(.horizontal)
                                }
                            }

                            Spacer(minLength: 100)
                        }
                        .padding(.top)
                    }
                    .refreshable { await load() }
                }
            }
            .navigationTitle("Explore")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationDestination(isPresented: Binding(
                get: { selectedBrowse != nil },
                set: { if !$0 { selectedBrowse = nil } }
            )) {
                if let bid = selectedBrowse {
                    BrowseDetailView(browseId: bid)
                }
            }
        }
        .task { await load() }
    }

    private func load() async {
        isLoading = true
        do {
            let r = try await APIClient.shared.fetchExplore()
            newReleases = r.newReleases
            moodsGenres = r.moodsAndGenres
        } catch {}
        isLoading = false
    }
}
