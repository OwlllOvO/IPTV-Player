import Foundation

/// A saved playlist URL with its optional user-agent for history.
struct PlaylistHistoryEntry: Identifiable, Codable, Equatable {
    let id: UUID
    var urlString: String
    var userAgent: String

    init(id: UUID = UUID(), urlString: String, userAgent: String = "") {
        self.id = id
        self.urlString = urlString
        self.userAgent = userAgent
    }
}
