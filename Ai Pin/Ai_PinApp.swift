import SwiftUI
import AppIntents
import PinKit
import SwiftData

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
    
    @State
    private var sceneModelContainer: ModelContainer
    
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
        
        let modelContainer = try! ModelContainer(for: _Note.self, configurations: .init("v1"))
        sceneModelContainer = modelContainer

        AppDependencyManager.shared.add(dependency: navigationStore)
        AppDependencyManager.shared.add(dependency: notesRepository)
        AppDependencyManager.shared.add(dependency: capturesRepository)
        AppDependencyManager.shared.add(dependency: myDataRepository)
        AppDependencyManager.shared.add(dependency: settingsRepository)
        AppDependencyManager.shared.add(dependency: modelContainer)
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
        .environment(\.database, SharedDatabase(modelContainer: sceneModelContainer).database)
        .modelContainer(sceneModelContainer)
    }
}
