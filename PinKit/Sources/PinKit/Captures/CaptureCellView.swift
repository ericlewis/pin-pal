import SwiftUI
import SDWebImageSwiftUI

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
            .aspectRatio(1, contentMode: .fit)
            .clipped()
    }
}
