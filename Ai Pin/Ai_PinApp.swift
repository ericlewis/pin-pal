import SwiftUI
import AppIntents

@main
struct Ai_PinApp: App {
    
    @State 
    private var sceneNavigationStore: NavigationStore
    
    @State
    private var sceneColorStore: ColorStore
    
    init() {
        let navigationStore = NavigationStore()
        sceneNavigationStore = navigationStore
        
        let colorStore = ColorStore()
        sceneColorStore = colorStore

        AppDependencyManager.shared.add(dependency: navigationStore)
        AppDependencyManager.shared.add(dependency: colorStore)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sceneNavigationStore)
                .environment(sceneColorStore)
                .tint(sceneColorStore.accentColor)
        }
    }
}
