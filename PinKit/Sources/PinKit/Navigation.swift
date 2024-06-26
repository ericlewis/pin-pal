import SwiftUI
import AppIntents
import Models

@Observable public class Navigation: @unchecked Sendable {
    public static let shared = Navigation()
    public var selectedTab: Tab = .notes

    public var authenticationPresented = false
    public var activeNote: NoteEnvelope?
    public var isWifiCodeGeneratorPresented = false
    public var fileImporterPresented = false
    public var textColorPresented = false
    public var iconChangerPresented = false
    public var showToast: Toast = .none
    public var blockPinConfirmationPresented = false
    public var deleteAllNotesConfirmationPresented = false
    
    public var savingNote = false
    
    public init() {}
    
    public func show(toast: Toast) {
        withAnimation {
            self.showToast = toast
        }
    }
    
    public func dismissToast() {
        withAnimation {
            self.showToast = .none
        }
    }
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
