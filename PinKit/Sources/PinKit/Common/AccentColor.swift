import SwiftUI

@propertyWrapper
public struct AccentColor: DynamicProperty {
    @AppStorage(Constants.UI_CUSTOM_ACCENT_COLOR_V1)
    public var wrappedValue: Color = .accentColor
    
    public var projectedValue: Binding<Color> {
        _wrappedValue.projectedValue
    }
    
    public init() {}
}

