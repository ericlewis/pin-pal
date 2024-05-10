import SwiftUI

struct CaptureImageContentModeKey: EnvironmentKey {
    static var defaultValue: ContentMode = .fill
}

extension EnvironmentValues {
    var imageContentMode: ContentMode {
        get { self[CaptureImageContentModeKey.self] }
        set { self[CaptureImageContentModeKey.self] = newValue }
    }
}
