import Foundation
import Models

extension VideoAsset {
    public func videoDownloadUrl(memoryUUID: UUID) -> URL? {
        return URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(memoryUUID)/file/\(fileUUID)/download")?.appending(queryItems: [
            URLQueryItem(name: "token", value: accessToken),
            URLQueryItem(name: "rawData", value: "false")
        ])
    }
}
