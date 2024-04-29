import Foundation

public struct FeatureFlagEnvelope: Codable {
    public enum State: String, Codable {
        case enabled
        case disabled
    }
    
    let state: State
    var bool: Bool {
        switch state {
        case .enabled: true
        case .disabled: false
        }
    }
}
