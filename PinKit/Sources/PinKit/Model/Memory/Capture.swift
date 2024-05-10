import SwiftData
import Foundation
import Models

public typealias Capture = SchemaV1._Capture_

extension SchemaV1 {
    
    @Model
    public final class _Capture_ {
        
        @Attribute(.unique)
        public var uuid: UUID
        
        public let state: CaptureState
        public let type: RemoteCaptureType
        public let isPhoto: Bool
        public let isVideo: Bool

        public let thumbnailUUID: UUID
        public let thumbnailAccessToken: String
        
        public let isFavorite: Bool
        public let createdAt: Date
        public let modifiedAt: Date

        public init(uuid: UUID, state: CaptureState, type: RemoteCaptureType, isPhoto: Bool, isVideo: Bool, thumbnailUUID: UUID, thumbnailAccessToken: String, isFavorite: Bool, createdAt: Date, modifiedAt: Date) {
            self.uuid = uuid
            self.state = state
            self.type = type
            self.isPhoto = isPhoto
            self.isVideo = isVideo
            self.thumbnailUUID = thumbnailUUID
            self.thumbnailAccessToken = thumbnailAccessToken
            self.createdAt = createdAt
            self.isFavorite = isFavorite
            self.modifiedAt = modifiedAt
        }
        
        public convenience init(from content: MemoryContentEnvelope) {
            guard let capture: CaptureEnvelope = content.get() else {
                fatalError()
            }
            
            self.init(
                uuid: content.id,
                state: capture.state,
                type: capture.type,
                isPhoto: capture.type == .photo,
                isVideo: capture.type == .video,
                thumbnailUUID: capture.thumbnail.fileUUID,
                thumbnailAccessToken: capture.thumbnail.accessToken,
                isFavorite: content.favorite,
                createdAt: content.userCreatedAt,
                modifiedAt: content.userLastModified
            )
        }
    }

}

extension Capture {
    public static func all(limit: Int? = nil, order: SortOrder = .reverse) -> FetchDescriptor<Capture> {
        var d = FetchDescriptor<Capture>(sortBy: [.init(\.createdAt, order: order)])
        if let limit {
            d.fetchLimit = limit
        }
        return d
    }
}

