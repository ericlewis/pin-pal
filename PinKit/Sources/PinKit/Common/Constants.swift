import SwiftUI

public struct Constants {
    public static let UI_CUSTOM_ACCENT_COLOR_V1 = "accentColor"
    public static let UI_CUSTOM_APP_ICON_V1 = "iconName"
    public static let ACCESS_TOKEN = "ACCESS_TOKEN_V1"
    public static let SUBSCRIPTION_INFO_CACHE = "SUBSCRIPTION_INFO_CACHE_V1"
    public static let EXTENDED_INFO_CACHE = "EXTENDED_INFO_CACHE_V1"
}


extension Constants {
    public static let defaultAppAccentColor = Color.accentColor
    public static let defaultAppIconName = ""
}

@propertyWrapper
public struct AccentColor: DynamicProperty {
    @AppStorage(Constants.UI_CUSTOM_ACCENT_COLOR_V1)
    public var wrappedValue: Color = .accentColor
    
    public init() {}
}
