import SwiftData
import Foundation
import UIKit
import CoreLocation

public enum MediaType: String, Codable {
    case video = "VIDEO"
    case photo = "PHOTO"
}

@Model
public final class Asset {
    
    public var fileUUID: UUID
    
    public var text: String?
    public var accessToken: String?
    public var key: String?
    public var url: URL?
    
    init(fileUUID: UUID, text: String?, accessToken: String?, key: String?, url: URL?) {
        self.fileUUID = fileUUID
        self.text = text
        self.accessToken = accessToken
        self.key = key
        self.url = url
    }
}

@Model
public final class Capture {
    
    @Attribute(.unique)
    public var uuid: UUID

    public var isFavorited: Bool
    public var createdAt: Date
    public var locationName: String?
    public var latitude: Double?
    public var longitude: Double?

    @Attribute(.unique)
    var thumbnail: Asset
    
    public init(
        uuid: UUID,
        isFavorited: Bool,
        createdAt: Date,
        thumbnail: Asset,
        locationName: String? = nil,
        latitude: Double? = 0,
        longitude: Double? = 0
    ) {
        self.uuid = uuid
        self.isFavorited = isFavorited
        self.createdAt = createdAt
        self.thumbnail = thumbnail
        self.locationName = locationName
        self.latitude = latitude
        self.longitude = longitude
    }
}

extension Capture {
    var locationCoordinates: CLLocationCoordinate2D? {
        guard let lat = latitude, let lng = longitude else {
            return nil
        }
        return .init(latitude: lat, longitude: lng)
    }
}

// UIKit specific things, prob should go elsewhere

extension Capture {
    func makeThumbnailURL() -> URL? {
        URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(uuid.uuidString)/file/\(thumbnail.fileUUID)")?.appending(queryItems: [
            .init(name: "token", value: thumbnail.accessToken),
            .init(name: "w", value: "320"),
            .init(name: "q", value: "75")
        ])
    }
}

extension Capture {
    func saveToCameraRoll() async throws {
        try await UIImageWriteToSavedPhotosAlbum(makeThumbnail(), nil, nil, nil)
    }
    
    func makeThumbnail() async throws -> UIImage {
        let (data, _) = try await URLSession.shared.data(from: URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(uuid)/file/\(thumbnail.fileUUID)")!.appending(queryItems: [
            .init(name: "token", value: thumbnail.accessToken),
            .init(name: "w", value: "640"),
            .init(name: "q", value: "100")
        ]))
        guard let image = UIImage(data: data) else {
            fatalError()
        }
        return image
    }
    
    func saveVideo(capture: ContentEnvelope) async throws {
//        guard let url = capture.videoDownloadUrl(), let accessToken = UserDefaults.standard.string(forKey: Constants.ACCESS_TOKEN) else { return }
//        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
//        let targetURL = tempDirectoryURL.appendingPathComponent(capture.uuid.uuidString).appendingPathExtension("mp4")
//        if try FileManager.default.fileExists(atPath: targetURL.path()) {
//            UISaveVideoAtPathToSavedPhotosAlbum(targetURL.path(), nil, nil, nil)
//        } else {
//            var req = URLRequest(url: url)
//            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
//            let (data, _) = try await URLSession.shared.data(for: req)
//            try FileManager.default.createFile(atPath: targetURL.path(), contents: data)
//            UISaveVideoAtPathToSavedPhotosAlbum(targetURL.path(), nil, nil, nil)
//        }
    }
}
