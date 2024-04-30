import SwiftUI
import SDWebImageSwiftUI

struct DataCellView: View {
    let event: EventContentEnvelope
    
    @AccentColor
    private var accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading) {
            switch event.eventData {
            case let .aiMic(event):
                Text(event.request)
                    .font(.headline)
                    .foregroundStyle(accentColor)
                Text(event.response)
            case let .music(event):
                LabeledContent {
                    if let id = event.albumArtUuid {
                        WebImage(url: makeAlbumURL(id: id))
                            .resizable()
                            .scaledToFit()
                            .frame(width: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                } label: {
                    if let title = event.trackTitle ?? event.prompt {
                        Text(title)
                            .font(.headline)
                            .foregroundStyle(accentColor)
                    }
                    if let artistName = event.artistName {
                        Text(artistName)
                    }
                    if let albumName = event.albumName {
                        Text(albumName)
                    }
                    
                }
            case let .call(event):
                Text(event.peers.map(\.displayName).joined(separator: ","))
                    .font(.headline)
                    .foregroundStyle(accentColor)
                if let duration = event.duration {
                    Text(duration.formatted())
                }
            case let .translation(event):
                HStack {
                    Text(event.originLanguage)
                        .font(.headline)
                    Spacer()
                    Text(event.targetLanguage)
                        .font(.headline)
                }
                .overlay {
                    Image(systemName: "arrow.forward")
                }
                .foregroundStyle(accentColor)
            case .unknown:
                Text("Unknown")
            }
            Text(event.eventCreationTime, format: .dateTime)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    func makeAlbumURL(id: UUID) -> URL? {
        URL(string: "https://humane.center/_next/image?url=https://resources.tidal.com/images/\(id.uuidString.split(separator: "-").joined(separator: "/"))/160x160.jpg&w=256&q=75".lowercased())
    }
}
