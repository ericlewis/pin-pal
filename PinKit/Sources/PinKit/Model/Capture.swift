import SwiftData
import Foundation

@Model
class Capture {
    var uuid: UUID
    let parentUUID: UUID
    
    let thumbnailUUID: UUID
    let thumbnailAccessToken: UUID
    
    init(uuid: UUID, parentUUID: UUID, thumbnailUUID: UUID, thumbnailAccessToken: UUID) {
        self.uuid = uuid
        self.parentUUID = parentUUID
        self.thumbnailUUID = thumbnailUUID
        self.thumbnailAccessToken = thumbnailAccessToken
    }
}

