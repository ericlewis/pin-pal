import Foundation

public struct FeatureFlagEnvelope: Codable {
    public enum State: String, Codable {
        case enabled
        case disabled
    }
    
    public init(state: State) {
        self.state = state
    }
    
    public var state: State
    public var isEnabled: Bool {
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
