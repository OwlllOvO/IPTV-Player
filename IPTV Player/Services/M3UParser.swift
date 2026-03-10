import Foundation

/// Fetches and parses M3U playlists from a URL.
/// Supports #EXTM3U / #EXTINF format; extracts channel titles and stream URLs.
final class M3UParser {

    /// Result of loading an M3U: either the list of channels or an error.
    enum LoadResult {
        case success([Channel])
        case failure(Error)
    }

    /// Load and parse an M3U playlist from `playlistURL`.
    /// - Parameters:
    ///   - playlistURL: URL of the M3U (e.g. https://example.com/playlist.m3u).
    ///   - userAgent: Optional User-Agent for the request. If nil, default is used.
    /// - Returns: Parsed channels or error.
    func load(playlistURL: URL, userAgent: String?) async -> LoadResult {
        var request = URLRequest(url: playlistURL)
        if let ua = userAgent, !ua.isEmpty {
            request.setValue(ua, forHTTPHeaderField: "User-Agent")
        }

        let data: Data
        do {
            let (d, _) = try await URLSession.shared.data(for: request)
            data = d
        } catch {
            return .failure(error)
        }

        return parse(data: data, baseURL: playlistURL)
    }

    /// Parse M3U content (e.g. from fetched data).
    /// - Parameters:
    ///   - data: Raw M3U bytes (UTF-8 or Latin-1).
    ///   - baseURL: Base URL used to resolve relative stream URLs.
    /// - Returns: Parsed channels or error.
    func parse(data: Data, baseURL: URL) -> LoadResult {
        guard let raw = String(data: data, encoding: .utf8)
            ?? String(data: data, encoding: .isoLatin1) else {
            return .failure(M3UError.invalidEncoding)
        }

        let lines = raw
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
            .components(separatedBy: "\n")

        var channels: [Channel] = []
        var currentTitle: String?
        var currentDuration: String?

        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty { continue }

            if trimmed.hasPrefix("#EXTINF:") {
                currentTitle = parseEXTINF(trimmed)
                currentDuration = nil
                continue
            }

            if trimmed.hasPrefix("#") {
                continue
            }

            // Line is a URL (or path)
            guard let streamURL = URL(string: trimmed, relativeTo: baseURL) ?? URL(string: trimmed),
                  streamURL.scheme != nil else {
                currentTitle = nil
                continue
            }

            let title = currentTitle ?? streamURL.lastPathComponent
            let channel = Channel(
                title: title,
                url: streamURL,
                userAgent: nil
            )
            channels.append(channel)
            currentTitle = nil
        }

        return .success(channels)
    }

    /// Parse #EXTINF line for display title.
    /// Format: #EXTINF:-1 tvg-id="..." tvg-name="..." ,Display Title
    private func parseEXTINF(_ line: String) -> String? {
        let prefix = "#EXTINF:"
        guard line.hasPrefix(prefix) else { return nil }
        let rest = String(line.dropFirst(prefix.count))
        if let comma = rest.firstIndex(of: ",") {
            return String(rest[rest.index(after: comma)...]).trimmingCharacters(in: .whitespaces)
        }
        return rest.trimmingCharacters(in: .whitespaces)
    }
}

enum M3UError: LocalizedError {
    case invalidEncoding

    var errorDescription: String? {
        switch self {
        case .invalidEncoding: return "Playlist encoding is not supported (use UTF-8 or Latin-1)."
        }
    }
}
