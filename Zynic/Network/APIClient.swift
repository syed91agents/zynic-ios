import Foundation

// Change this to your deployed server URL
let BASE_URL = "https://crops-fruit-lists-want.trycloudflare.com"

enum APIError: Error {
    case badURL, noData, decodingError(Error), serverError(Int)
}

final class APIClient {
    static let shared = APIClient()
    private let session: URLSession

    private init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 20
        config.timeoutIntervalForResource = 60
        session = URLSession(configuration: config)
    }

    // MARK: - Generic fetch
    func fetch<T: Decodable>(_ endpoint: String, type: T.Type) async throws -> T {
        guard let url = URL(string: BASE_URL + endpoint) else { throw APIError.badURL }
        let (data, response) = try await session.data(from: url)
        if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
            throw APIError.serverError(http.statusCode)
        }
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw APIError.decodingError(error)
        }
    }

    // MARK: - Home
    func fetchHome() async throws -> [Shelf] {
        let r = try await fetch("/api/home", type: HomeResponse.self)
        return r.shelves
    }

    // MARK: - Search
    func search(_ query: String) async throws -> [Track] {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let r = try await fetch("/api/search?q=\(q)", type: SearchResponse.self)
        return r.results
    }

    // MARK: - Suggestions
    func suggestions(_ query: String) async throws -> [String] {
        let q = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        struct Resp: Codable { var suggestions: [String] }
        let r = try await fetch("/api/suggestions?q=\(q)", type: Resp.self)
        return r.suggestions
    }

    // MARK: - Explore
    func fetchExplore() async throws -> ExploreResponse {
        return try await fetch("/api/explore", type: ExploreResponse.self)
    }

    // MARK: - Charts
    func fetchCharts() async throws -> [Shelf] {
        let r = try await fetch("/api/charts", type: ChartsResponse.self)
        return r.charts
    }

    // MARK: - Browse
    func browse(_ id: String) async throws -> BrowseDetail {
        let encoded = id.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? id
        return try await fetch("/api/browse?id=\(encoded)", type: BrowseDetail.self)
    }

    // MARK: - Stream
    func stream(_ videoId: String) async throws -> StreamResponse {
        return try await fetch("/api/stream?id=\(videoId)", type: StreamResponse.self)
    }

    // MARK: - Lyrics
    func lyrics(title: String, artist: String) async throws -> LyricsResponse {
        let t = title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? title
        let a = artist.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? artist
        return try await fetch("/api/lyrics?title=\(t)&artist=\(a)", type: LyricsResponse.self)
    }

    // MARK: - Resolve stream URL to absolute
    func resolveStreamURL(_ path: String) -> URL? {
        if path.hasPrefix("http") { return URL(string: path) }
        return URL(string: BASE_URL + path)
    }
}
