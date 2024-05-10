import Foundation

public struct LostDeviceEnvelope: Codable {
    public var isLost: Bool
    public let deviceId: String
    
    public init(isLost: Bool, deviceId: String) {
        self.isLost = isLost
        self.deviceId = deviceId
    }
}
