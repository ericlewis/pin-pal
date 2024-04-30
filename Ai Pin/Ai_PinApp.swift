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
    
    @AppStorage(Constant.UI_CUSTOM_ACCENT_COLOR_V1)
    private var accentColor: Color = Constant.defaultAppAccentColor

    init() {
        let navigationStore = NavigationStore()
        sceneNavigationStore = navigationStore
        
        let api = HumaneCenterService.live()
        sceneApi = api
        
        let notesRepository = NotesRepository(api: api)
        sceneNotesRepository = notesRepository
        
        let capturesRepository = CapturesRepository(api: api)
        sceneCapturesRepository = capturesRepository

        AppDependencyManager.shared.add(dependency: navigationStore)
        AppDependencyManager.shared.add(dependency: notesRepository)
        AppDependencyManager.shared.add(dependency: capturesRepository)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sceneNotesRepository)
                .environment(sceneCapturesRepository)
                .environment(sceneNavigationStore)
                .environment(sceneApi)
                .tint(accentColor)
        }
    }
}
