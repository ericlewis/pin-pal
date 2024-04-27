import SwiftUI
import AppIntents

@Observable final class NavigationStore: Sendable {
    var selectedTab: Tab = .notes
    
    var notesNavigationPath = NavigationPath()
    
    var authenticationPresented = false
    var newNotePresented = false
    var isWifiPresented = false
}


enum Tab: String, AppEnum {
    case notes
    case captures
    case myData
    case settings
    case contacts
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "App Tab"
    static var caseDisplayRepresentations: [Tab: DisplayRepresentation] = [
        .notes: "Notes",
        .captures: "Captures",
        .myData: "My Data",
        .settings: "Settings",
        .contacts: "Contacts"
    ]
}
