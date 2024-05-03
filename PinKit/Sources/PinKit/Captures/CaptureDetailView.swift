import SwiftUI
import SDWebImageSwiftUI
import MapKit

struct LocationContent: View {
    
    var memory: Memory
    
    var body: some View {
        if let location = memory.location {
            Map {
                Marker("", coordinate: location.coordinates)
            }
            .aspectRatio(1.777, contentMode: .fit)
            .listRowInsets(.init())
            LabeledContent("Location", value: location.name)
        }
    }
}

struct CaptureDetailView: View {
    
    var capture: Capture
    
    @Environment(HumaneCenterService.self)
    private var service

    @Environment(\.database)
    private var database
    
    var body: some View {
        List {
            Section {
                LabeledContent("Created") {
                    Text(capture.createdAt, format: .dateTime)
                }
                if let memory = capture.memory {
                    LocationContent(memory: memory)
                }
            } header: {
                if capture.video != nil {
                    VideoPlayerView(capture: capture)
                        .mask(RoundedRectangle(cornerRadius: 8))
                        .listRowInsets(.init())
                        .padding(.vertical)
                } else {
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
        }
        .toolbar {
            Menu("Options", systemImage: "ellipsis.circle") {
                 CaptureMenuContents(capture: capture)
            }
        }
        .navigationTitle("Capture")
        .task {
            do {
                guard var memory = capture.memory,
                      let captureDetails: CaptureEnvelope = try await service.memory(memory.uuid).get(),
                      let name = captureDetails.location,
                      let latitude = captureDetails.latitude,
                      let longitude = captureDetails.longitude else {
                    return
                }
                memory.location = .init(name: name, latitude: latitude, longitude: longitude)
            } catch {
                print(error)
            }
        }
    }
}
