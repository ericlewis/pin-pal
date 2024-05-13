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
    private var sceneModelContainer: ModelContainer

    @Environment(\.scenePhase)
    private var phase
    
    let sceneDatabase: any Database

    init() {
        let navigationStore = Navigation.shared
        sceneNavigationStore = navigationStore
        
        let service = HumaneCenterService.live()
        sceneService = service

        let schema = Schema(CurrentScheme.models)
        let modelContainer: ModelContainer = {
            do {
                let modelContainerConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
                return try ModelContainer(for: schema, configurations: modelContainerConfig)
            } catch {
                let modelContainerConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                do {
                    return try ModelContainer(for: schema, configurations: modelContainerConfig)
                } catch {
                    fatalError("\(error)")
                }
            }
        }()
        sceneModelContainer = modelContainer
        
        let database = SharedDatabase(modelContainer: modelContainer).database
        sceneDatabase = database
        
        let appState = AppState()
        sceneAppState = appState

        AppDependencyManager.shared.add(dependency: appState)
        AppDependencyManager.shared.add(dependency: navigationStore)
        AppDependencyManager.shared.add(dependency: service)
        AppDependencyManager.shared.add(dependency: database)
        
        /**
         Call `updateAppShortcutParameters` on `AppShortcutsProvider` so that the system updates the App Shortcut phrases with any changes to
         the app's intent parameters. The app needs to call this function during its launch, in addition to any time the parameter values for
         the shortcut phrases change.
         */
        PinPalShortcuts.updateAppShortcutParameters()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sceneNavigationStore)
                .environment(sceneService)
                .environment(sceneAppState)
                .environment(\.database, sceneDatabase)
                .defaultAppStorage(.init(suiteName: "group.com.ericlewis.Pin-Pal") ?? .standard)
                .modelContainer(sceneModelContainer)
                .onChange(of: phase) { oldPhase, newPhase in
                    switch (oldPhase, newPhase) {
                    case (.inactive, .background):
                        if sceneService.isLoggedIn() {
                            requestRefreshBackgroundTask(for: .notes)
                            requestRefreshBackgroundTask(for: .captures)
                            requestRefreshBackgroundTask(for: .myData)
                        }
                    default: break
                    }
                }
        }
        .backgroundTask(.appRefresh(Constants.taskId(for: .notes))) {
            await handleNotesRefresh()
        }
        .backgroundTask(.appRefresh(Constants.taskId(for: .captures))) {
            await handleCapturesRefresh()
        }
        .backgroundTask(.appRefresh(Constants.taskId(for: .myData))) {
            await handleMyDataRefresh()
        }
    }
}

extension PinPalApp {
    func requestRefreshBackgroundTask(for id: SyncIdentifier) {
        let request = BGAppRefreshTaskRequest(identifier: Constants.taskId(for: id))
        request.earliestBeginDate = Date(timeIntervalSinceNow: 1 * 60) // 1 min
        do {
            try BGTaskScheduler.shared.submit(request)
            print("submitted bg task: \(id.rawValue)")
        } catch {
            print("Could not schedule app refresh: \(error) for \(id.rawValue)")
        }
    }
    
    func handleNotesRefresh() async {
        do {
            let intent = SyncNotesIntent()
            intent.database = sceneDatabase
            intent.service = sceneService
            intent.app = sceneAppState
            let _ = try await intent.perform()
            requestRefreshBackgroundTask(for: .notes)
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
            requestRefreshBackgroundTask(for: .captures)
        } catch {
            
        }
    }
    
    func handleMyDataRefresh() async {
        Task {
            let intent = SyncAiMicEventsIntent()
            intent.database = sceneDatabase
            intent.service = sceneService
            intent.app = sceneAppState
            let _ = try await intent.perform()
            requestRefreshBackgroundTask(for: .myData)
        }
        Task {
            let intent = SyncMusicEventsIntent()
            intent.database = sceneDatabase
            intent.service = sceneService
            intent.app = sceneAppState
            let _ = try await intent.perform()
            requestRefreshBackgroundTask(for: .myData)
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
