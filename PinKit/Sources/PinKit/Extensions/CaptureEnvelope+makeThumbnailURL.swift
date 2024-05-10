import Foundation
import Models

extension CaptureEnvelope {
    public func makeThumbnailURL() -> URL? {
        URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(self.memoryId!)/file/\(self.thumbnail.fileUUID)")?.appending(queryItems: [
            .init(name: "token", value: self.thumbnail.accessToken),
            .init(name: "w", value: "640"),
            .init(name: "q", value: "100")
        ])
    }
}
