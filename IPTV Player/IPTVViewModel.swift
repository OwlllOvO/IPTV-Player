import AVKit
import Combine
import Foundation
import SwiftUI

private let playlistHistoryKey = "IPTVPlayer.playlistHistory"
private let maxPlaylistHistoryCount = 50

/// View model: M3U URL + optional user-agent, parsed channels, playback with per-URL user-agent.
final class IPTVViewModel: ObservableObject {
    @Published var m3uURLString: String = ""
    @Published var playlistUserAgent: String = ""
    @Published var channels: [Channel] = []
    @Published var selectedChannelID: String?
    @Published var isLoading = false
    @Published var loadError: String?
    @Published var player: AVPlayer?
    @Published var playerContentID = UUID()
    @Published var playlistHistory: [PlaylistHistoryEntry] = []

    private let parser = M3UParser()
    private let playerService = PlayerService()

    init() {
        loadPlaylistHistory()
    }

    /// User-agent to use when loading the M3U URL (for fetching the playlist).
    var playlistUA: String? {
        let ua = playlistUserAgent.trimmingCharacters(in: .whitespaces)
        return ua.isEmpty ? nil : ua
    }

    func loadPlaylist() {
        let urlString = m3uURLString.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: urlString), url.scheme != nil else {
            loadError = "Please enter a valid URL."
            return
        }

        loadError = nil
        isLoading = true

        Task { @MainActor in
            let result = await parser.load(playlistURL: url, userAgent: playlistUA)
            isLoading = false
            switch result {
            case .success(let list):
                channels = list
                selectedChannelID = nil
                loadError = nil
                addToPlaylistHistory(urlString: urlString, userAgent: playlistUserAgent.trimmingCharacters(in: .whitespaces))
            case .failure(let error):
                channels = []
                loadError = error.localizedDescription
            }
        }
    }

    /// Apply a history entry: fill URL + user-agent and load the playlist.
    func applyHistoryEntry(_ entry: PlaylistHistoryEntry) {
        m3uURLString = entry.urlString
        playlistUserAgent = entry.userAgent
        loadPlaylist()
    }

    /// Remove an entry from history.
    func removeHistoryEntry(_ entry: PlaylistHistoryEntry) {
        playlistHistory.removeAll { $0.id == entry.id }
        savePlaylistHistory()
    }

    private func addToPlaylistHistory(urlString: String, userAgent: String) {
        let trimmed = urlString.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        var list = playlistHistory.filter { $0.urlString.trimmingCharacters(in: .whitespaces) != trimmed }
        list.insert(PlaylistHistoryEntry(urlString: trimmed, userAgent: userAgent), at: 0)
        playlistHistory = Array(list.prefix(maxPlaylistHistoryCount))
        savePlaylistHistory()
    }

    private func loadPlaylistHistory() {
        guard let data = UserDefaults.standard.data(forKey: playlistHistoryKey),
              let decoded = try? JSONDecoder().decode([PlaylistHistoryEntry].self, from: data) else {
            return
        }
        playlistHistory = decoded
    }

    private func savePlaylistHistory() {
        guard let data = try? JSONEncoder().encode(playlistHistory) else { return }
        UserDefaults.standard.set(data, forKey: playlistHistoryKey)
    }

    /// Select a channel and start playback. Uses the playlist's custom user-agent for the stream URL.
    func selectAndPlay(_ channel: Channel) {
        selectedChannelID = channel.id
        // User-agent for playback: per-URL. We use the same custom UA as the playlist if one was set.
        playerService.play(url: channel.url, userAgent: playlistUA)
        player = playerService.player
        playerContentID = UUID()
    }
}
