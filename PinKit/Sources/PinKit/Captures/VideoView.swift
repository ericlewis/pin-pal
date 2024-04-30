import SwiftUI
import AVKit

extension URL {
    static func videoDownloadUrl(uuid: UUID, fileUUID: UUID, accessToken: String) -> URL? {
        return URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(uuid)/file/\(fileUUID)/download")?.appending(queryItems: [
            URLQueryItem(name: "token", value: accessToken),
            URLQueryItem(name: "rawData", value: "false")
        ])
    }
}

extension ContentEnvelope {
    func videoDownloadUrl() -> URL? {
        guard let cap: CaptureEnvelope = self.get(), let vid = cap.video else {
            return nil
        }
        return URL.videoDownloadUrl(uuid: uuid, fileUUID: vid.fileUUID, accessToken: vid.accessToken)
    }
}

struct VideoView: View {
    
    let id: UUID
    let vidUrl: URL
    
    private static let aspectRatio: Double = 960 / 720
    
    @AppStorage(Constants.ACCESS_TOKEN)
    private var accessToken: String?
    
    @State
    private var player = AVPlayer()
    
    var body: some View {
        VideoPlayer(player: player)
            .aspectRatio(Self.aspectRatio, contentMode: .fit)
            .task {
                let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let targetURL = tempDirectoryURL.appendingPathComponent(id.uuidString).appendingPathExtension("mp4")
                do {
                    if try FileManager.default.fileExists(atPath: targetURL.path()) {
                        player.replaceCurrentItem(with: .init(url: targetURL))
                    } else {
                        var req = URLRequest(url: vidUrl)
                        req.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
                        let (data, _) = try await URLSession.shared.data(for: req)
                        try FileManager.default.createFile(atPath: targetURL.path(), contents: data)
                        player.replaceCurrentItem(with: .init(url: targetURL))
                    }
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

