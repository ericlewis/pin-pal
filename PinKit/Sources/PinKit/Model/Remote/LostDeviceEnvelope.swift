import Foundation

public struct LostDeviceEnvelope: Codable {
    public var isLost: Bool
    let deviceId: String
}
