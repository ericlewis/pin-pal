import Foundation

public struct LostDeviceEnvelope: Codable {
    var isLost: Bool
    let deviceId: String
}
