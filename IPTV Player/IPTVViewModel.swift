import AVKit
import Combine
import Foundation
import SwiftUI

/// View model: M3U URL + optional user-agent, parsed channels, playback with per-URL user-agent.
final class IPTVViewModel: ObservableObject {
    @Published var m3uURLString: String = ""
    @Published var playlistUserAgent: String = ""
    @Published var channels: [Channel] = []
    @Published var selectedChannelID: String?
    @Published var isLoading = false
    @Published var loadError: String?
    @Published var playerLayer: AVPlayerLayer?
    @Published var playerContentID = UUID()

    private let parser = M3UParser()
    private let playerService = PlayerService()

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
            case .failure(let error):
                channels = []
                loadError = error.localizedDescription
            }
        }
    }

    /// Select a channel and start playback. Uses the playlist's custom user-agent for the stream URL.
    func selectAndPlay(_ channel: Channel) {
        selectedChannelID = channel.id
        // User-agent for playback: per-URL. We use the same custom UA as the playlist if one was set.
        playerService.play(url: channel.url, userAgent: playlistUA)
        if let layer = playerService.playerLayer {
            playerLayer = layer
            playerContentID = UUID()
        }
    }
}
