import SwiftUI
import SDWebImageSwiftUI

struct CaptureCellBottomBar: View {
    
    var capture: Capture
    
    var body: some View {
        HStack {
            if let memory = capture.memory, memory.favorite {
                Image(systemName: "heart")
            }
            Spacer()
            if capture.type == .video {
                Image(systemName: "play")
            }
        }
        .padding(5)
        .symbolVariant(.fill)
        .imageScale(.small)
        .shadow(color: .black, radius: 6)
        .tint(.white)
    }
}

struct CaptureCellView: View {
    
    var capture: Capture
    
    var body: some View {
        Rectangle()
            .fill(.bar)
            .overlay {
                WebImage(url: capture.makeThumbnailURL()) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    ProgressView()
                }
            }
            .overlay(alignment: .bottom) {
                CaptureCellBottomBar(capture: capture)
            }
            .aspectRatio(1, contentMode: .fit)
            .clipped()
    }
}
