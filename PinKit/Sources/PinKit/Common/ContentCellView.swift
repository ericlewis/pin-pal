import SwiftUI
import SDWebImageSwiftUI

struct ContentCellView: View {
    let content: ContentEnvelope
    
    @AccentColor
    private var accentColor: Color
    
    var body: some View {
        switch content.data {
        case let .capture(capture):
            WebImage(url: makeThumbnailURL(capture: capture)) { image in
                image
                    .resizable()
                    .aspectRatio(1, contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(.bar)
                    .overlay {
                        ProgressView()
                    }
                    .aspectRatio(1, contentMode: .fill)
            }
            .overlay(alignment: .bottomLeading) {
                if content.favorite {
                    Image(systemName: "heart")
                        .symbolVariant(.fill)
                        .imageScale(.small)
                        .padding(5)
                        .foregroundStyle(.white)
                        .shadow(radius: 3)
                }
            }
        case let .note(note):
            LabeledContent {} label: {
                Text(note.title)
                    .foregroundStyle(accentColor)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .overlay(alignment: .topTrailing) {
                        if content.favorite {
                            Image(systemName: "heart")
                                .symbolVariant(.fill)
                                .foregroundStyle(.red)
                        }
                    }
                Text(LocalizedStringKey(note.text))
                Text(content.userCreatedAt, format: .dateTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        case .unknown:
            LabeledContent {} label: {
                Text("Unknown")
                    .foregroundStyle(.red)
                    .font(.headline)
                Text(content.userCreatedAt, format: .dateTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
    
    func makeThumbnailURL(capture: CaptureEnvelope) -> URL? {
        URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(content.uuid.uuidString)/file/\(capture.thumbnail.fileUUID)")?.appending(queryItems: [
            .init(name: "token", value: capture.thumbnail.accessToken),
            .init(name: "w", value: "640"),
            .init(name: "q", value: "100")
        ])
    }
}
