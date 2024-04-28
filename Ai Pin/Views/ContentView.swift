import SwiftUI

struct ContentView: View {
    @Environment(NavigationStore.self) 
    private var navigationStore

    var body: some View {
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
        .environment(navigationStore)
    }
}

#Preview {
    ContentView()
}
