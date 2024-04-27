import SwiftUI
import AppIntents

@main
struct Ai_PinApp: App {
    
    @State
    private var sceneNavigationStore: NavigationStore
    
    init() {
        let navigationStore = NavigationStore()
        sceneNavigationStore = navigationStore

        AppDependencyManager.shared.add(dependency: navigationStore)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sceneNavigationStore)
        }
    }
}
