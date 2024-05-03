import Foundation
import SwiftData

@Model
public final class Asset {
    
    var fileUUID: UUID
    
    var accessToken: String
    
    var capture: Capture?
    
    init(fileUUID: UUID, accessToken: String, capture: Capture? = nil) {
        self.fileUUID = fileUUID
        self.accessToken = accessToken
        self.capture = capture
    }
}
