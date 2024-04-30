import SwiftUI
import AppIntents

@Observable public class NavigationStore: @unchecked Sendable {
    public var selectedTab: Tab = .notes
    
    public var notesNavigationPath = NavigationPath()
    public var capturesNavigationPath = NavigationPath()
    
    public var authenticationPresented = false
    public var activeNote: Note?
    public var isWifiCodeGeneratorPresented = false
    
    public var textColorPresented = false
    public var iconChangerPresented = false
    
    public init() {}
}

public enum Tab: String, AppEnum {
    case notes
    case captures
    case myData
    case settings
    case contacts
    case dashboard
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = "App Tab"
    public static var caseDisplayRepresentations: [Tab: DisplayRepresentation] = [
        .notes: "Notes",
        .captures: "Captures",
        .myData: "My Data",
        .settings: "Settings",
        .contacts: "Contacts",
        .dashboard: "Memories"
    ]
}
