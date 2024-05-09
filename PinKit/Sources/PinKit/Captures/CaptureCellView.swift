import SwiftUI
import SDWebImageSwiftUI

struct CaptureCellView: View {
    
    @Environment(\.imageContentMode)
    private var contentMode
    
    var capture: Capture

    var body: some View {
        WebImage(url: makeThumbnailURL(capture: capture)) { image in
            Rectangle()
                .fill(.background)
                .overlay {
                    image
                        .resizable()
                        .aspectRatio(contentMode: contentMode)
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
                    if capture.isFavorite {
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
    }
    
    func makeThumbnailURL(capture: Capture) -> URL? {
        makeThumbnailURL(uuid: capture.uuid, fileUUID: capture.thumbnailUUID, accessToken: capture.thumbnailAccessToken)
    }
    
    func makeThumbnailURL(uuid: UUID, fileUUID: UUID, accessToken: String) -> URL? {
        URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(uuid.uuidString)/file/\(fileUUID)")?.appending(queryItems: [
            .init(name: "token", value: accessToken),
            .init(name: "w", value: "640"),
            .init(name: "q", value: "100")
        ])
    }
}
