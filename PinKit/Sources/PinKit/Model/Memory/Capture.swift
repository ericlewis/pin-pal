import SwiftData
import Foundation

public typealias Capture = SchemaV1.Capture

extension SchemaV1 {
    
    @Model
    public final class Capture {
        
        @Attribute(.unique)
        public var uuid: UUID
        
        public let state: CaptureState
        public let type: CaptureType
        public let isPhoto: Bool

        public let thumbnailUUID: UUID
        public let thumbnailAccessToken: String
        
        public let isFavorite: Bool
        public let createdAt: Date
        public let modifiedAt: Date

        public init(uuid: UUID, state: CaptureState, type: CaptureType, isPhoto: Bool, thumbnailUUID: UUID, thumbnailAccessToken: String, isFavorite: Bool, createdAt: Date, modifiedAt: Date) {
            self.uuid = uuid
            self.state = state
            self.type = type
            self.isPhoto = isPhoto
            self.thumbnailUUID = thumbnailUUID
            self.thumbnailAccessToken = thumbnailAccessToken
            self.createdAt = createdAt
            self.isFavorite = isFavorite
            self.modifiedAt = modifiedAt
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

