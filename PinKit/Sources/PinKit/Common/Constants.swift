import SwiftUI

public struct Constants {
    public static let UI_CUSTOM_ACCENT_COLOR_V1 = "accentColor"
    public static let UI_CUSTOM_APP_ICON_V1 = "iconName"
    public static let UI_DATE_FORMAT = "UI_DATE_FORMAT_V1"
    public static let ACCESS_TOKEN = "ACCESS_TOKEN_V1"
    public static let SUBSCRIPTION_INFO_CACHE = "SUBSCRIPTION_INFO_CACHE_V1"
    public static let EXTENDED_INFO_CACHE = "EXTENDED_INFO_CACHE_V1"
    public static let LAST_SESSION = "LAST_SESSION_V1"
}


extension Constants {
    public static let defaultAppAccentColor = Color.accentColor
    public static let defaultAppIconName = ""
}

public enum SyncIdentifier: String {
    case notes
    case captures
    case myData
}

extension Constants {
    public static func taskId(for id: SyncIdentifier) -> String {
        switch id {
        case .captures: "com.ericlewis.Pin-Pal.Captures.refresh"
        case .myData: "com.ericlewis.Pin-Pal.MyData.refresh"
        case .notes: "com.ericlewis.Pin-Pal.Notes.refresh"
        }
    }
}
