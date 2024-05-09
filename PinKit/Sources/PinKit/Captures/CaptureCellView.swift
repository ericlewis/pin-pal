import SwiftUI
import SDWebImageSwiftUI

struct CaptureCellView: View {
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
                VStack {
                    HStack {
                        Spacer()
                        if capture.state != .processed {
                            Image(systemName: "icloud.and.arrow.up")
                        }
                    }
                    Spacer()
                    HStack {
                        if content.favorite {
                            Image(systemName: "heart")
                        }
                        Spacer()
                        if capture.type == .video {
                            Image(systemName: "play")
                        }
                    }
                }
                .padding(5)
                .symbolVariant(.fill)
                .imageScale(.small)
                .foregroundStyle(.white)
                .shadow(color: .black, radius: 5)
            }
        default:
            LabeledContent {} label: {
                Text("Unknown")
                    .foregroundStyle(.red)
                    .font(.headline)
                DateTextView(date: content.userCreatedAt)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
    }
    
    func makeThumbnailURL(capture: CaptureEnvelope) -> URL? {
        URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(content.uuid)/file/\(capture.thumbnail.fileUUID)")?.appending(queryItems: [
            .init(name: "token", value: capture.thumbnail.accessToken),
            .init(name: "w", value: "320"),
            .init(name: "q", value: "75")
        ])
    }
}
