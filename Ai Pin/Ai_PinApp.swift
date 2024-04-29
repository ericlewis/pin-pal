import SwiftUI
import AppIntents
import PinKit

@main
struct Ai_PinApp: App {
    
    @State 
    private var sceneNavigationStore: NavigationStore
    
    @AppStorage(Constant.UI_CUSTOM_ACCENT_COLOR_V1)
    private var accentColor: Color = Constant.defaultAppAccentColor

    init() {
        let navigationStore = NavigationStore()
        sceneNavigationStore = navigationStore

        AppDependencyManager.shared.add(dependency: navigationStore)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(sceneNavigationStore)
                .tint(accentColor)
        }
    }
}
