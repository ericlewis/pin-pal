import SwiftUI
import AppIntents
import PinKit
import SwiftData
import BackgroundTasks

@main
struct PinPalApp: App {
    
    #if os(iOS)
    @UIApplicationDelegateAdaptor(AppDelegate.self)
    var appDelegate
    #endif
    
    @State
    private var sceneAppState: AppState

    @State
    private var sceneNavigationStore: Navigation
    
    @State
    private var sceneService: HumaneCenterService

    @State
    private var sceneCapturesRepository: CapturesRepository
    
    @State
    private var sceneMyDataRepository: MyDataRepository

    @State
    private var sceneModelContainer: ModelContainer

    @Environment(\.scenePhase)
    private var phase
    
    let sceneDatabase: any Database

    init() {
        let navigationStore = Navigation.shared
        sceneNavigationStore = navigationStore
        
        let service = HumaneCenterService.live()
        sceneService = service
        
        let capturesRepository = CapturesRepository(api: service)
        sceneCapturesRepository = capturesRepository
        
        let myDataRepository = MyDataRepository(api: service)
        sceneMyDataRepository = myDataRepository

        let schema = Schema(CurrentScheme.models)
        let modelContainerConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let modelContainer = try! ModelContainer(for: schema, configurations: modelContainerConfig)
        sceneModelContainer = modelContainer
        
        let database = SharedDatabase(modelContainer: modelContainer).database
        sceneDatabase = database
        
        let appState = AppState()
        sceneAppState = appState

        AppDependencyManager.shared.add(dependency: appState)
        AppDependencyManager.shared.add(dependency: navigationStore)
        AppDependencyManager.shared.add(dependency: capturesRepository)
        AppDependencyManager.shared.add(dependency: myDataRepository)
        AppDependencyManager.shared.add(dependency: service)
        AppDependencyManager.shared.add(dependency: database)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .environment(sceneCapturesRepository)
        .environment(sceneNavigationStore)
        .environment(sceneMyDataRepository)
        .environment(sceneService)
        .environment(sceneAppState)
        .environment(\.database, sceneDatabase)
        .defaultAppStorage(.init(suiteName: "group.com.ericlewis.Pin-Pal") ?? .standard)
        .modelContainer(sceneModelContainer)
        .backgroundTask(.appRefresh("com.ericlewis.Pin-Pal.Notes.refresh")) {
            await handleNotesRefresh()
        }
        .backgroundTask(.appRefresh("com.ericlewis.Pin-Pal.Captures.refresh")) {
            await handleCapturesRefresh()
        }
        .onChange(of: phase) { oldPhase, newPhase in
            switch (oldPhase, newPhase) {
            case (.inactive, .background):
                requestNotesRefreshBackgroundTask()
                requestCapturesRefreshBackgroundTask()
            default: break
            }
        }
    }
    
    func requestNotesRefreshBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.ericlewis.Pin-Pal.Notes.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60) // 5 min
        do {
            try BGTaskScheduler.shared.submit(request)
            print("submitted bg task")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func requestCapturesRefreshBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: "com.ericlewis.Pin-Pal.Captures.refresh")
        request.earliestBeginDate = Date(timeIntervalSinceNow: 5 * 60) // 5 min
        do {
            try BGTaskScheduler.shared.submit(request)
            print("submitted bg task")
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    func handleNotesRefresh() async {
        do {
            let intent = SyncNotesIntent()
            intent.database = sceneDatabase
            intent.service = sceneService
            intent.app = sceneAppState
            let _ = try await intent.perform()
            requestNotesRefreshBackgroundTask()
        } catch {
            
        }
    }
    
    func handleCapturesRefresh() async {
        do {
            let intent = SyncCapturesIntent()
            intent.database = sceneDatabase
            intent.service = sceneService
            intent.app = sceneAppState
            let _ = try await intent.perform()
            requestCapturesRefreshBackgroundTask()
        } catch {
            
        }
    }
}

#if os(iOS)
class AppDelegate: NSObject, UIApplicationDelegate {

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let sceneConfiguration = UISceneConfiguration(name: "Custom Configuration", sessionRole: connectingSceneSession.role)
        sceneConfiguration.delegateClass = SceneDelegate.self
        return sceneConfiguration
    }
    
    class SceneDelegate: UIResponder, UIWindowSceneDelegate {
        func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
            if Navigation.shared.activeNote == nil {
                Navigation.shared.activeNote = .create()
            }
        }
    }
}
#endif
