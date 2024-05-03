import SwiftData
import Foundation
import UIKit
import CoreLocation

@Model
public final class Capture {
    
    static let all = FetchDescriptor<Capture>()
    static func id(_ id: UUID) -> FetchDescriptor<Capture> {
        let predicate = #Predicate<Capture> {
            $0.uuid == id
        }
        return FetchDescriptor<Capture>(predicate: predicate)
    }

    @Attribute(.unique)
    public var uuid: UUID
    
    public var type: CaptureType
    
    public var createdAt: Date
    
    public var memory: Memory?
    
    @Relationship(deleteRule: .cascade, inverse: \Asset.capture)
    public var thumbnail: Asset?
    
    @Relationship(deleteRule: .cascade, inverse: \Asset.capture)
    public var video: Asset?
    
    @Relationship(deleteRule: .cascade, inverse: \Asset.capture)
    public var originals: [Asset]

    @Relationship(deleteRule: .cascade, inverse: \Asset.capture)
    public var derivatives: [Asset]
    
    public init(
        uuid: UUID,
        type: CaptureType,
        createdAt: Date,
        memory: Memory? = nil,
        thumbnail: Asset? = nil,
        video: Asset? = nil,
        originals: [Asset],
        derivatives: [Asset]
    ) {
        self.uuid = uuid
        self.memory = memory
        self.createdAt = createdAt
        self.type = type
        self.thumbnail = thumbnail
        self.video = video
        self.originals = originals
        self.derivatives = derivatives
    }
}

// UIKit specific things, prob should go elsewhere

extension Capture {
    func makeThumbnailURL(width: Int = 320, quality: Int = 75) -> URL? {
        guard let uuid = memory?.uuid.uuidString, let fileUUID = thumbnail?.fileUUID.uuidString, let accessToken = thumbnail?.accessToken else {
            return nil
        }
        return URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(uuid)/file/\(fileUUID)")?.appending(queryItems: [
            .init(name: "token", value: accessToken),
            .init(name: "w", value: String(width)),
            .init(name: "q", value: String(quality))
        ])
    }
}

enum CaptureError: Error {
    case imageSaveError
}

extension Capture {
    func saveToCameraRoll() async throws {
        if video == nil {
            guard let thumbnail = try await makeThumbnail() else {
                throw CaptureError.imageSaveError
            }
            try await UIImageWriteToSavedPhotosAlbum(thumbnail, nil, nil, nil)
        } else {
            try await saveVideo()
        }
    }
    
    func makeThumbnail() async throws -> UIImage? {
        guard let uuid = memory?.uuid,
              let fileUUID = thumbnail?.fileUUID,
              let accessToken = thumbnail?.accessToken else {
            return nil
        }
        let (data, _) = try await URLSession.shared.data(from: URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(uuid)/file/\(thumbnail)")!.appending(queryItems: [
            .init(name: "token", value: accessToken),
            .init(name: "w", value: "640"),
            .init(name: "q", value: "100")
        ]))
        guard let image = UIImage(data: data) else {
            fatalError()
        }
        return image
    }
    
    func makeVideoDownloadUrl() -> URL? {
        guard let uuid = memory?.uuid, let videoFileUUID = video?.fileUUID, let videoAccessToken = video?.accessToken else { return nil }
        return URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(uuid)/file/\(videoFileUUID)/download")?.appending(queryItems: [
            URLQueryItem(name: "token", value: videoAccessToken),
            URLQueryItem(name: "rawData", value: "false")
        ])
    }
    
    func saveVideo() async throws {
        guard let url = makeVideoDownloadUrl(), let accessToken = UserDefaults.standard.string(forKey: Constants.ACCESS_TOKEN) else { return }
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let targetURL = tempDirectoryURL.appendingPathComponent(uuid.uuidString).appendingPathExtension("mp4")
        var req = URLRequest(url: url)
        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        let (data, _) = try await URLSession.shared.data(for: req)
        try? FileManager.default.removeItem(at: targetURL)
        try FileManager.default.createFile(atPath: targetURL.path(), contents: data)
        UISaveVideoAtPathToSavedPhotosAlbum(targetURL.path(), nil, nil, nil)
    }
}
