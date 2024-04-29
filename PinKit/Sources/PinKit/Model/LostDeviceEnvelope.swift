import Foundation

public struct LostDeviceEnvelope: Codable {
    let isLost: Bool
    let deviceId: String
}
