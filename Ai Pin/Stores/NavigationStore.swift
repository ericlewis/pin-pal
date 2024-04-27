import SwiftUI

@Observable class NavigationStore {
    var selectedTab: Tab = .notes
    var authenticationPresented = false
    var notesNavigationPath = NavigationPath()
}

enum Tab {
    case notes
    case captures
    case myData
    case settings
    case contacts
    case agents
}
