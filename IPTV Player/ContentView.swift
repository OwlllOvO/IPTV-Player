import AppKit
import AVKit
import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel = IPTVViewModel()

    var body: some View {
        NavigationSplitView {
            sidebar
        } detail: {
            playerSection
        }
    }

    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 12) {
            playlistSection
            Divider()
            channelListSection
        }
        .frame(minWidth: 260, idealWidth: 320, maxWidth: 400)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .navigationTitle("IPTV Player")
    }

    private var playlistSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("M3U Playlist URL")
                .font(.headline)

            TextField("https://example.com/playlist.m3u", text: $viewModel.m3uURLString)
                .textFieldStyle(.roundedBorder)

            Text("Custom User-Agent (optional, used only for this playlist URL)")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextField("Leave empty for default", text: $viewModel.playlistUserAgent)
                .textFieldStyle(.roundedBorder)

            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("Loading…")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let err = viewModel.loadError {
                    Text(err)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .lineLimit(2)
                }
                Spacer()
                Button("Load playlist") {
                    viewModel.loadPlaylist()
                }
                .disabled(viewModel.m3uURLString.trimmingCharacters(in: .whitespaces).isEmpty || viewModel.isLoading)
                .buttonStyle(.borderedProminent)
            }

            if !viewModel.playlistHistory.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("History")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(alignment: .leading, spacing: 4) {
                            ForEach(viewModel.playlistHistory) { entry in
                                PlaylistHistoryRowView(
                                    entry: entry,
                                    onSelect: { viewModel.applyHistoryEntry(entry) },
                                    onRemove: { viewModel.removeHistoryEntry(entry) }
                                )
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 120)
                }
            }
        }
    }

    private var channelListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Channels")
                    .font(.headline)
                if !viewModel.channels.isEmpty {
                    Text("(\(viewModel.channels.count))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if viewModel.channels.isEmpty && !viewModel.isLoading {
                Text("Enter an M3U URL and tap Load playlist.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            } else {
                List(viewModel.channels, selection: $viewModel.selectedChannelID) { channel in
                    ChannelRowView(channel: channel)
                        .tag(channel.id)
                }
                .listStyle(.sidebar)
                .onChange(of: viewModel.selectedChannelID) { oldValue, newValue in
                    if let channelID = newValue,
                       let channel = viewModel.channels.first(where: { $0.id == channelID }) {
                        viewModel.selectAndPlay(channel)
                    }
                }
            }
        }
    }

    private var playerSection: some View {
        ZStack {
            Color.black

            if let player = viewModel.player {
                VideoPlayerView(player: player)
                    .id(viewModel.playerContentID)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "play.rectangle")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Select a channel to play")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(minWidth: 480)
    }
}

struct PlaylistHistoryRowView: View {
    let entry: PlaylistHistoryEntry
    let onSelect: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 6) {
            Button {
                onSelect()
            } label: {
                VStack(alignment: .leading, spacing: 2) {
                    Text(entry.urlString)
                        .font(.caption)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                    if !entry.userAgent.isEmpty {
                        Text("UA: \(entry.userAgent)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
                .background(Color(NSColor.controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 4))
            }
            .buttonStyle(.plain)

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }
}

struct ChannelRowView: View {
    let channel: Channel

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(channel.title)
                .font(.body)
                .lineLimit(1)
            if channel.userAgent != nil {
                Text("Custom UA")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

/// Wraps AVPlayerView for SwiftUI, providing native macOS playback controls.
struct VideoPlayerView: NSViewRepresentable {
    let player: AVPlayer

    func makeNSView(context: Context) -> AVPlayerView {
        let view = AVPlayerView()
        view.player = player
        view.controlsStyle = .inline
        return view
    }

    func updateNSView(_ nsView: AVPlayerView, context: Context) {
        if nsView.player !== player {
            nsView.player = player
        }
    }
}

#Preview {
    ContentView()
        .frame(width: 900, height: 600)
}
