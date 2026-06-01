import SwiftUI

class LibraryStore: ObservableObject {
    static let shared = LibraryStore()
    @Published var items: [LibraryItem] = []

    private init() { load() }

    func add(_ track: Track) {
        guard !items.contains(where: { $0.track.id == track.id }) else { return }
        items.insert(LibraryItem(track: track, addedAt: Date()), at: 0)
        save()
    }

    func remove(_ track: Track) {
        items.removeAll { $0.track.id == track.id }
        save()
    }

    func contains(_ track: Track) -> Bool {
        items.contains { $0.track.id == track.id }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: "zynic_library")
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: "zynic_library"),
           let decoded = try? JSONDecoder().decode([LibraryItem].self, from: data) {
            items = decoded
        }
    }
}

struct LibraryView: View {
    @ObservedObject var library = LibraryStore.shared
    @ObservedObject var player = AudioPlayerManager.shared

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                if library.items.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "heart.circle")
                            .font(.system(size: 70))
                            .foregroundStyle(LinearGradient(colors: [.purple, .indigo], startPoint: .top, endPoint: .bottom))
                        Text("Your Library")
                            .font(.system(size: 22, weight: .bold))
                        Text("Tracks you like will appear here.\nTap ♥ while a song is playing.")
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .font(.system(size: 14))
                    }
                    .padding()
                } else {
                    List {
                        ForEach(library.items) { item in
                            TrackRowView(track: item.track, index: nil) {
                                let tracks = library.items.map { $0.track }
                                let idx = library.items.firstIndex { $0.id == item.id } ?? 0
                                player.play(tracks: tracks, startAt: idx)
                            }
                            .swipeActions(edge: .trailing) {
                                Button(role: .destructive) {
                                    library.remove(item.track)
                                } label: {
                                    Label("Remove", systemImage: "trash")
                                }
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparatorTint(Color.white.opacity(0.07))
                        }
                    }
                    .listStyle(.plain)
                    .background(Color.black)
                }
            }
            .navigationTitle("Library ♥")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                if !library.items.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            player.play(tracks: library.items.map { $0.track }, startAt: 0)
                        } label: {
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.purple)
                        }
                    }
                }
            }
        }
    }
}
