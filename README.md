# IPTV Player (macOS)

A native macOS app that plays IPTV streams from M3U playlist URLs, with optional custom User-Agent per playlist.

## Requirements

- macOS 13.0 or later
- Xcode 15+ (for building)

## Features

- **M3U URL input**: Enter a URL to an M3U playlist; the app fetches and parses it and lists all programs.
- **Custom User-Agent**: Optionally set a User-Agent that is used only for that playlist URL—both when fetching the M3U and when playing each stream. If left empty, the system default is used. The User-Agent is paired with the URL (not global).
- **Playback**: Select a channel from the list to play. Streams are loaded with the same User-Agent as the playlist (if set).

## Build and run

1. Open `IPTV Player.xcodeproj` in Xcode.
2. Choose the **IPTV Player** scheme and a Mac destination.
3. Press **Run** (⌘R).

## Usage

1. Paste your M3U playlist URL (e.g. `https://example.com/playlist.m3u`) into **M3U Playlist URL**.
2. Optionally set **Custom User-Agent** for this URL (used for fetching the playlist and for every stream from it).
3. Click **Load playlist** to fetch and parse the playlist.
4. Click a channel in the list to start playback in the player area on the right.

## Project structure

- **IPTV Player/** – App target
  - `IPTVPlayerApp.swift` – App entry point
  - `ContentView.swift` – Main UI (playlist input, channel list, player)
  - `IPTVViewModel.swift` – State and coordination (load M3U, play with UA)
  - **Models/** – `Channel.swift` (channel title, URL, optional UA)
  - **Services/** – `M3UParser.swift` (fetch + parse M3U), `PlayerService.swift` (AVPlayer with per-URL User-Agent)

## License

MIT
