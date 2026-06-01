import Foundation

// MARK: - Track
struct Track: Identifiable, Codable, Equatable, Hashable {
    var id: String
    var title: String
    var subtitle: String?
    var artist: String?
    var thumbnail: String?
    var type: String?
    var videoId: String?
    var browseId: String?
    var playlistId: String?
    var duration: String?

    var displayArtist: String { artist ?? subtitle ?? "Unknown Artist" }
    var thumbnailURL: URL? { thumbnail.flatMap { URL(string: $0) } }
}

// MARK: - Shelf
struct Shelf: Identifiable, Codable {
    var id: String { title }
    var title: String
    var items: [Track]
}

// MARK: - SearchResult
struct SearchResponse: Codable {
    var results: [Track]
}

// MARK: - HomeResponse
struct HomeResponse: Codable {
    var shelves: [Shelf]
}

// MARK: - ExploreResponse
struct ExploreResponse: Codable {
    var newReleases: [Track]
    var moodsAndGenres: [Track]
}

// MARK: - ChartsResponse
struct ChartsResponse: Codable {
    var charts: [Shelf]
}

// MARK: - StreamResponse
struct StreamResponse: Codable {
    var url: String
    var title: String?
    var artist: String?
    var lengthSeconds: Int?
    var mimeType: String?
    var contentLength: Int?
}

// MARK: - LyricsResponse
struct LyricsResponse: Codable {
    var synced: Bool
    var lyrics: String
}

// MARK: - BrowseDetail
struct BrowseDetail: Codable {
    var id: String?
    var title: String?
    var subtitle: String?
    var thumbnail: String?
    var tracks: [Track]?
    var sections: [Shelf]?
    var thumbnailURL: URL? { thumbnail.flatMap { URL(string: $0) } }
}

// MARK: - LibraryItem
struct LibraryItem: Identifiable, Codable {
    var id: String { track.id }
    var track: Track
    var addedAt: Date
}
