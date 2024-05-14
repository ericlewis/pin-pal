import SwiftUI
import SDWebImageSwiftUI

struct MusicCellContent: View {
    let event: MusicEvent
    
    @AccentColor
    private var accentColor: Color
    
    var body: some View {
        LabeledContent {
            if event.sourceService == "TIDAL" {
                if let id = event.albumArtUUID {
                    WebImage(url: makeAlbumURL(id: id)) { image in
                        image
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    } placeholder: {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(.bar)
                            .frame(width: 60, height: 60)
                            .overlay(ProgressView())
                    }
                }
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.bar)
                    .frame(width: 60, height: 60)
                    .overlay() {
                        Image(systemName: "music.note")
                    }
            }
        } label: {
            if let title = event.trackTitle ?? event.prompt {
                Text(title)
                    .font(.headline)
                    .foregroundStyle(accentColor)
            }
            if let length = event.trackCount {
                Text("^[\(length) track](inflect: true)")
            }
            if let artistName = event.artistName {
                Text(artistName)
            }
            if let albumName = event.albumName {
                Text(albumName)
            }
            LabeledContent {
                
            } label: {
                DateTextView(date: event.createdAt)
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
        }
        .tint(.primary)
    }
    
    func makeAlbumURL(id: UUID) -> URL? {
        URL(string: "https://humane.center/_next/image?url=https://resources.tidal.com/images/\(id.uuidString.split(separator: "-").joined(separator: "/"))/160x160.jpg&w=256&q=75".lowercased())
    }
}

struct MusicCellView: View {
    let event: MusicEvent
    
    @AccentColor
    private var accentColor: Color
    
    @Environment(\.openURL)
    private var openURL
    
    var body: some View {
        Group {
            /* if let playlist = event.generatedPlaylist {
             NavigationLink {
             SmartPlaylistView(playlist: playlist, event: event)
             } label: {
             LabeledContent {} label: {
             if let title = event.prompt {
             Text(title)
             .font(.headline)
             .foregroundStyle(accentColor)
             }
             if let length = event.length, let lengthCount = Int(length) {
             Text("^[\(lengthCount) track](inflect: true)")
             }
             LabeledContent {
             
             } label: {
             DateTextView(date: createdAt)
             .foregroundStyle(.tertiary)
             .font(.caption)
             }
             }
             }
             } else */ if let trackId = event.sourceTrackId, event.sourceService == "TIDAL" {
                 Button {
                     if let trackUrl = makeTidalTrackURL(trackID: trackId) {
                         openURL(trackUrl)
                     }
                 } label: {
                     MusicCellContent(event: event)
                 }
             } else {
                 MusicCellContent(event: event)
             }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            DeleteEventButton(event: event)
        }
        #if os(visionOS)
        .buttonStyle(.plain)
        .buttonBorderShape(.roundedRectangle)
        #endif
    }
    
    func makeTidalTrackURL(trackID: String) -> URL? {
        URL(string: "https://tidal.com/browse/track/\(trackID)")
    }
}
