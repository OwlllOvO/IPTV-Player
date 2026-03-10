import Foundation

/// A single channel/stream from an M3U playlist.
struct Channel: Identifiable, Equatable {
    let id: String
    let title: String
    let url: URL
    /// Optional custom User-Agent for this channel's stream URL. Nil means use default.
    let userAgent: String?

    init(id: String? = nil, title: String, url: URL, userAgent: String? = nil) {
        self.id = id ?? url.absoluteString
        self.title = title
        self.url = url
        self.userAgent = userAgent
    }
}
