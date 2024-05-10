import SwiftUI
import Models

struct SmartPlaylistView: View {
    let playlist: RemoteSmartGeneratedPlaylist
    let event: RemoteMusicEvent

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
