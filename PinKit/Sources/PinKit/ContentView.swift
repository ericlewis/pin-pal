import SwiftUI
import SDWebImage

public struct ContentView: View {
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(CaptureSyncEngine.self)
    private var captureSyncEngine
    
    @Environment(NoteSyncEngine.self)
    private var noteSyncEngine

    public init() {
        SDWebImageManager.shared.cacheKeyFilter = SDWebImageCacheKeyFilter { url in
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.query = nil
            return components?.url?.absoluteString ?? ""
        }
    }
    
    public var body: some View {
        @Bindable
        var navigationStore = navigationStore
        TabView(selection: $navigationStore.selectedTab) {
            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
                .tag(Tab.notes)
            CapturesView()
                .tabItem {
                    Label("Captures", systemImage: "camera.aperture")
                }
                .tag(Tab.captures)
            MyDataView()
                .tabItem {
                    Label("My Data", systemImage: "person.text.rectangle")
                }
                .tag(Tab.myData)
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(Tab.settings)
        }
        .modifier(AuthHandlerViewModifier())
        .task {
            do {
                while !Task.isCancelled {
                    await captureSyncEngine.sync()
                    try await Task.sleep(for: .seconds(5))
                }
            } catch {
                print(error)
            }
        }
        .task {
            do {
                while !Task.isCancelled {
                    await noteSyncEngine.sync()
                    try await Task.sleep(for: .seconds(5))
                }
            } catch {
                print(error)
            }
        }
    }
}

#Preview {
    ContentView()
}
