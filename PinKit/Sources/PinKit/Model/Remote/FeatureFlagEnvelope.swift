import Foundation

public struct FeatureFlagEnvelope: Codable {
    public enum State: String, Codable {
        case enabled
        case disabled
    }
    
    var state: State
    var isEnabled: Bool {
        get {
            switch state {
            case .enabled: true
            case .disabled: false
            }
        }
        set {
            if newValue {
                state = .enabled
            } else {
                state = .disabled
            }
        }
    }
}
