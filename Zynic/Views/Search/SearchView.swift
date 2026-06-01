import SwiftUI

struct SearchView: View {
    @ObservedObject var player = AudioPlayerManager.shared
    @State private var query = ""
    @State private var results: [Track] = []
    @State private var suggestions: [String] = []
    @State private var isSearching = false
    @State private var isLoadingSuggestions = false
    @State private var showSuggestions = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Search bar
                    HStack(spacing: 12) {
                        HStack(spacing: 8) {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.secondary)
                            TextField("Songs, artists, albums…", text: $query)
                                .focused($focused)
                                .autocorrectionDisabled()
                                .onSubmit { Task { await search() } }
                                .onChange(of: query) { newVal in
                                    if newVal.isEmpty {
                                        results = []; suggestions = []; showSuggestions = false
                                    } else {
                                        showSuggestions = true
                                        Task { await loadSuggestions(newVal) }
                                    }
                                }
                            if !query.isEmpty {
                                Button { query = ""; results = []; suggestions = []; showSuggestions = false } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        if focused {
                            Button("Cancel") {
                                query = ""; focused = false; results = []; showSuggestions = false
                            }
                            .foregroundColor(.purple)
                        }
                    }
                    .padding()
                    .animation(.easeInOut(duration: 0.2), value: focused)

                    if isSearching {
                        Spacer()
                        ProgressView().tint(.purple).scaleEffect(1.3)
                        Spacer()
                    } else if showSuggestions && !suggestions.isEmpty && results.isEmpty {
                        // Suggestions list
                        List(suggestions, id: \.self) { s in
                            Button(action: {
                                query = s; showSuggestions = false; Task { await search() }
                            }) {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                        .foregroundColor(.secondary).font(.system(size: 13))
                                    Text(s).foregroundColor(.primary)
                                    Spacer()
                                    Image(systemName: "arrow.up.left")
                                        .foregroundColor(.secondary).font(.system(size: 11))
                                }
                            }
                            .listRowBackground(Color.clear)
                        }
                        .listStyle(.plain)
                        .background(Color.black)
                    } else if !results.isEmpty {
                        // Results
                        List {
                            ForEach(Array(results.enumerated()), id: \.element.id) { idx, track in
                                TrackRowView(track: track, index: idx + 1) {
                                    smartPlay(track: track, allResults: results)
                                }
                                .listRowBackground(Color.clear)
                                .listRowSeparatorTint(Color.white.opacity(0.07))
                                .background(
                                    NavigationLink("", destination: {
                                        if let bid = track.browseId { BrowseDetailView(browseId: bid) }
                                        else { EmptyView() }
                                    }).opacity(0)
                                )
                            }
                        }
                        .listStyle(.plain)
                        .background(Color.black)
                    } else if query.isEmpty {
                        // Empty state
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "waveform.and.magnifyingglass")
                                .font(.system(size: 60))
                                .foregroundColor(.purple.opacity(0.4))
                            Text("Search for music")
                                .foregroundColor(.secondary)
                            Text("Find your favourite songs, artists and albums")
                                .font(.system(size: 13))
                                .foregroundColor(.secondary.opacity(0.7))
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                        Spacer()
                    } else {
                        Spacer()
                        Text("No results for \"\(query)\"")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .navigationTitle("Search")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    private func smartPlay(track: Track, allResults: [Track]) {
        if let vid = track.videoId, !vid.isEmpty {
            let playable = allResults.filter { $0.videoId != nil && !($0.videoId ?? "").isEmpty }
            let idx = playable.firstIndex(where: { $0.id == track.id }) ?? 0
            player.play(tracks: playable, startAt: idx)
        } else if track.id.count == 11 {
            player.play(track)
        }
        // If browseId → NavigationLink handles it (see background modifier above)
    }

    private func search() async {
        guard !query.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        focused = false; showSuggestions = false; isSearching = true
        do {
            results = try await APIClient.shared.search(query)
        } catch { results = [] }
        isSearching = false
    }

    private func loadSuggestions(_ q: String) async {
        do {
            suggestions = try await APIClient.shared.suggestions(q)
        } catch { suggestions = [] }
    }
}
