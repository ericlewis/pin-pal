import Foundation

extension URL {
    static func videoDownloadUrl(uuid: UUID, fileUUID: UUID, accessToken: String) -> URL? {
        return URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(uuid)/file/\(fileUUID)/download")?.appending(queryItems: [
            URLQueryItem(name: "token", value: accessToken),
            URLQueryItem(name: "rawData", value: "false")
        ])
    }
}
