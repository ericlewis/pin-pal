import SwiftUI
import AppIntents
import PinKit
import SwiftData

@main
struct Ai_PinApp: App {
    
    @State
    private var sceneNavigationStore: NavigationStore
    
    @State
    private var sceneService: HumaneCenterService

    @State
    private var sceneMyDataRepository: MyDataRepository
    
    @State
    private var sceneSettingsRepository: SettingsRepository
    
    @State
    private var sceneModelContainer: ModelContainer
    
    @AccentColor
    private var accentColor: Color
    
    let sceneDatabase: any Database

    public init() {
        let navigationStore = NavigationStore()
        sceneNavigationStore = navigationStore
        
        let service = HumaneCenterService.live()
        sceneService = service
  
        let myDataRepository = MyDataRepository(api: service)
        sceneMyDataRepository = myDataRepository
        
        let settingsRepository = SettingsRepository(service: service)
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
        AppDependencyManager.shared.add(dependency: service)
        AppDependencyManager.shared.add(dependency: database)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sceneNavigationStore)
                .environment(sceneMyDataRepository)
                .environment(sceneSettingsRepository)
                .environment(sceneService)
                .tint(accentColor)
        }
        .environment(\.database, sceneDatabase)
        .modelContainer(sceneModelContainer)
    }
}
