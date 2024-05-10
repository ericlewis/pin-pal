import SwiftUI
import AVKit
import Models

struct VideoView: View {
    
    let capture: Capture
    
    private static let aspectRatio: Double = 960 / 720
    
    @AppStorage(Constants.ACCESS_TOKEN)
    private var accessToken: String?
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @State
    private var player = AVPlayer()
    
    var body: some View {
        VideoPlayer(player: player)
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            .task {
                do {
                    let intent = GetVideoIntent(capture: capture)
                    intent.service = service
                    guard let result = try await intent.perform().value, let result else {
                        return
                    }
                    let targetURL = URL.temporaryDirectory.appending(path: result.filename)
                    try FileManager.default.createFile(atPath: targetURL.path(), contents: result.data)
                    player.replaceCurrentItem(with: .init(url: targetURL))
                    await player.seek(to: .zero)
                    player.isMuted = true
                    player.play()
                } catch let error {
                    print("Unable to copy file: \(error)")
                }
            }
            .onDisappear {
                player.pause()
            }
            .background {
                Color.black
            }
    }
}

