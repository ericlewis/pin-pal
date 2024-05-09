import SwiftData
import Foundation

@Model
public final class Capture {
    public var uuid: UUID
    public let parentUUID: UUID
    
    public let thumbnailUUID: UUID
    public let thumbnailAccessToken: UUID
    
    public init(uuid: UUID, parentUUID: UUID, thumbnailUUID: UUID, thumbnailAccessToken: UUID) {
        self.uuid = uuid
        self.parentUUID = parentUUID
        self.thumbnailUUID = thumbnailUUID
        self.thumbnailAccessToken = thumbnailAccessToken
    }
}

