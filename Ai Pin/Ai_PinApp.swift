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
    private var sceneMyDataRepository: MyDataRepository
    
    @State
    private var sceneSettingsRepository: SettingsRepository
    
    @State
    private var sceneModelContainer: ModelContainer
    
    @AccentColor
    private var accentColor: Color
    
    let sceneDatabase: any Database

    init() {
        let navigationStore = NavigationStore()
        sceneNavigationStore = navigationStore
        
        let api = HumaneCenterService.live()
        sceneApi = api
  
        let myDataRepository = MyDataRepository(api: api)
        sceneMyDataRepository = myDataRepository
        
        let settingsRepository = SettingsRepository(service: api)
        sceneSettingsRepository = settingsRepository
        
        let modelContainerConfig = ModelConfiguration("v1.38", isStoredInMemoryOnly: false)
        let modelContainer = try! ModelContainer(
            for: Memory.self,
            configurations: modelContainerConfig
        )
        sceneModelContainer = modelContainer
        
        let database = SharedDatabase(modelContainer: modelContainer).database
        sceneDatabase = database

        AppDependencyManager.shared.add(dependency: navigationStore)
        AppDependencyManager.shared.add(dependency: myDataRepository)
        AppDependencyManager.shared.add(dependency: settingsRepository)
        AppDependencyManager.shared.add(dependency: database)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sceneNavigationStore)
                .environment(sceneMyDataRepository)
                .environment(sceneSettingsRepository)
                .environment(sceneApi)
                .tint(accentColor)
        }
        .environment(\.database, sceneDatabase)
        .modelContainer(sceneModelContainer)
    }
}
