import AVFoundation
import Foundation

/// Plays a stream URL with an optional custom User-Agent (per-URL, not global).
final class PlayerService: ObservableObject {

    private(set) var player: AVPlayer?
    private var currentURL: URL?
    private var currentUserAgent: String?

    /// Play a stream. Uses custom User-Agent if provided; otherwise system default.
    func play(url: URL, userAgent: String?) {
        currentURL = url
        currentUserAgent = userAgent

        let options: [String: Any]
        if let ua = userAgent, !ua.isEmpty {
            // AVURLAssetHTTPUserAgentKey (macOS 13+): per-URL User-Agent for playback
            options = ["AVURLAssetHTTPUserAgentKey": ua]
        } else {
            options = [:]
        }

        let asset = AVURLAsset(url: url, options: options)
        let item = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: item)
        newPlayer.play()

        player?.pause()
        player = newPlayer
    }

    func pause() {
        player?.pause()
    }

    func resume() {
        player?.play()
    }

    func stop() {
        player?.pause()
        player = nil
        currentURL = nil
        currentUserAgent = nil
    }
}
