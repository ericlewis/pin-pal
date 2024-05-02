import SwiftUI
import SDWebImageSwiftUI
import MapKit

struct CaptureDetailView: View {
    
    var capture: Capture
    
    @Environment(HumaneCenterService.self)
    private var service

    var body: some View {
        List {
            Section {
                LabeledContent("Created") {
                    Text(capture.createdAt, format: .dateTime)
                }
                if let locationName = capture.locationName {
                    LabeledContent("Location", value: locationName)
                }
                if let location = capture.locationCoordinates {
                    Map {
                        Marker("", coordinate: location)
                    }
                    .aspectRatio(1.777, contentMode: .fit)
                    .listRowInsets(.init())
                }
            } header: {
                WebImage(url: capture.makeThumbnailURL()) { image in
                    image
                        .resizable()
                        .scaledToFill()
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } placeholder: {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.bar)
                        .overlay(ProgressView())
                }
                .listRowInsets(.init())
                .padding(.vertical)
            }
        }
        .toolbar {
            Menu("Options", systemImage: "ellipsis.circle") {
                 CaptureMenuContents(capture: capture)
            }
        }
        .navigationTitle("Capture")
        .task {
            do {
                guard let captureDetails: CaptureEnvelope = try await service.memory(self.capture.uuid).get() else {
                    return
                }
                withAnimation {
                    capture.locationName = captureDetails.location
                    capture.latitude = captureDetails.latitude
                    capture.longitude = captureDetails.longitude
                }
            } catch {
                print(error)
            }
        }
    }
}
