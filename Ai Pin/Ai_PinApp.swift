import SwiftUI
import AppIntents
import PinKit

@main
struct Ai_PinApp: App {
    
    @State 
    private var sceneNavigationStore: NavigationStore
    
    @State
    private var sceneApi: HumaneCenterService
    
    @State
    private var sceneNotesRepository: NotesRepository
    
    @State
    private var sceneCapturesRepository: CapturesRepository
    
    @State
    private var sceneMyDataRepository: MyDataRepository
    
    @State
    private var sceneSettingsRepository: SettingsRepository
    
    @AccentColor
    private var accentColor: Color

    init() {
        let navigationStore = NavigationStore()
        sceneNavigationStore = navigationStore
        
        let api = HumaneCenterService.live()
        sceneApi = api
        
        let notesRepository = NotesRepository(api: api)
        sceneNotesRepository = notesRepository
        
        let capturesRepository = CapturesRepository(api: api)
        sceneCapturesRepository = capturesRepository
        
        let myDataRepository = MyDataRepository(api: api)
        sceneMyDataRepository = myDataRepository
        
        let settingsRepository = SettingsRepository(service: api)
        sceneSettingsRepository = settingsRepository

        AppDependencyManager.shared.add(dependency: navigationStore)
        AppDependencyManager.shared.add(dependency: notesRepository)
        AppDependencyManager.shared.add(dependency: capturesRepository)
        AppDependencyManager.shared.add(dependency: myDataRepository)
        AppDependencyManager.shared.add(dependency: settingsRepository)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sceneNotesRepository)
                .environment(sceneCapturesRepository)
                .environment(sceneNavigationStore)
                .environment(sceneMyDataRepository)
                .environment(sceneSettingsRepository)
                .environment(sceneApi)
                .tint(accentColor)
        }
    }
}

/// These are shortcut stubs needed so they will be exposed to the system

public struct _CreateNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Create Note"
    
    @Parameter(title: "Title")
    public var title: String
    
    @Parameter(title: "Text")
    public var text: String
    
    public init(title: String, text: String) {
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var navigationStore: NavigationStore
    
    @Dependency
    public var notesRepository: NotesRepository
    
    public func perform() async throws -> some IntentResult {
        try await CreateNoteIntent(title: title, text: text).perform()
    }
}


public struct _UpdateNoteIntent: AppIntent {
    public static var title: LocalizedStringResource = "Update Note"
    
    @Parameter(title: "Identifier", description: "The identifier is from the parent memory.")
    public var identifier: String
    
    @Parameter(title: "Title")
    public var title: String
    
    @Parameter(title: "Text")
    public var text: String
    
    public init(identifier: String, title: String, text: String) {
        self.identifier = identifier
        self.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var navigationStore: NavigationStore
    
    @Dependency
    public var notesRepository: NotesRepository
    
    public func perform() async throws -> some IntentResult {
        try await UpdateNoteIntent(identifier: identifier, title: title, text: text).perform()
    }
}
