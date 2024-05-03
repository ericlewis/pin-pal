import SwiftUI
import AVKit

struct VideoPlayerView: View {
    
    var capture: Capture
    
    private static let aspectRatio: Double = 960 / 720
    
    @AppStorage(Constants.ACCESS_TOKEN)
    private var accessToken: String?
    
    @State
    private var player = AVPlayer()
    
    var body: some View {
        VideoPlayer(player: player)
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            .task(load)
            .onDisappear {
                player.pause()
            }
            .background {
                Color.black
            }
    }
    
    func load() async {
        do {
            guard let url = capture.makeVideoDownloadUrl(), let accessToken = UserDefaults.standard.string(forKey: Constants.ACCESS_TOKEN) else { return }
            let targetURL = URL.temporaryDirectory.appendingPathComponent(capture.uuid.uuidString).appendingPathExtension("mp4")
            if try FileManager.default.fileExists(atPath: targetURL.path()) {
                player.replaceCurrentItem(with: .init(url: targetURL))
                player.play()
            } else {
                var req = URLRequest(url: url)
                req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                req.setValue("mp4/video", forHTTPHeaderField: "accept")
                let (data, _) = try await URLSession.shared.data(for: req)
                try FileManager.default.createFile(atPath: targetURL.path(), contents: data)
                player.replaceCurrentItem(with: .init(url: targetURL))
                try Task.checkCancellation()
                player.play()
            }
        } catch {
            let targetURL = URL.temporaryDirectory.appendingPathComponent(capture.uuid.uuidString).appendingPathExtension("mp4")
            try? FileManager.default.removeItem(at: targetURL)
            print(error)
        }
    }
}

