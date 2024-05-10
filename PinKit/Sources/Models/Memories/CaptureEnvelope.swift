import Foundation

public enum RemoteCaptureType: String, Codable {
    case photo = "PHOTO"
    case video = "VIDEO"
}

public struct CaptureEnvelope: Codable, Hashable {
    let uuid: UUID
    public let type: RemoteCaptureType
    public let thumbnail: FileAsset
    public let closeupAsset: FileAsset?
    public var memoryId: UUID?
    public let video: VideoAsset?
    
    let originalThumbnails: [FileAsset]?
    public let originals: [FileAsset]?
    public let derivatives: [FileAsset]?
    public let location: String?
    public let latitude: Double?
    public let longitude: Double?
    public let state: CaptureState
}

public struct FileAsset: Codable, Hashable {
    public let fileUUID: UUID
    public let accessToken: String
}

public struct VideoAsset: Codable, Hashable {
    public let fileUUID: UUID
    public let accessToken: String
}

public enum CaptureState: String, Codable, Hashable {
    case pending = "PENDING_UPLOAD"
    case processed = "PROCESSED"
    case processing = "PROCESSING"
    
    public var title: String {
        switch self {
        case .pending:
            "Pending upload"
        case .processed:
            "Processed"
        case .processing:
            "Processing"
        }
    }
}
