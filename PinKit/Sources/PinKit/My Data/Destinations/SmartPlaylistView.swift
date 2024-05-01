import SwiftUI

struct SmartPlaylistView: View {
    let playlist: SmartGeneratedPlaylist
    let event: MusicEvent

    var body: some View {
        List {
            ForEach(playlist.tracks, id: \.title) { track in
                LabeledContent {} label: {
                    Text(track.title)
                    Text(ListFormatter.localizedString(byJoining: track.artists))
                }
            }
        }
        .navigationTitle(event.prompt ?? "Playlist")
    }
}
