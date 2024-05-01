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
                Rectangle()
                    .overlay {
                        image
                            .resizable()
                            .scaledToFill()
                    }
                    .aspectRatio(1, contentMode: .fill)
                    .clipped()
            } placeholder: {
                Rectangle()
                    .fill(.bar)
                    .overlay {
                        ProgressView()
                    }
                    .aspectRatio(1, contentMode: .fill)
            }
            .overlay(alignment: .bottom) {
                HStack {
                    if content.favorite {
                        Image(systemName: "heart")
                    }
                    Spacer()
                    if capture.video != nil {
                        Image(systemName: "play")
                    }
                }
                .padding(5)
                .symbolVariant(.fill)
                .imageScale(.small)
                .foregroundStyle(.white)
                .shadow(color: .black, radius: 5)
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
                    .lineLimit(note.text.count > 500 ? 5 : nil)
                Text(content.userCreatedAt, format: .dateTime)
                    .font(.caption)
                    .foregroundStyle(.tertiary)
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
            .init(name: "w", value: "320"),
            .init(name: "q", value: "75")
        ])
    }
}
