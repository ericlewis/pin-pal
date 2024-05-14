import SwiftUI
import SDWebImage

public struct ContentView: View {
    
    @Environment(Navigation.self)
    private var navigation
    
    @AccentColor
    private var tint
    
    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @State
    private var network = NetworkMonitor()
    
    public init() {
        SDWebImageManager.shared.cacheKeyFilter = SDWebImageCacheKeyFilter { url in
            if url.host() == "humane.center" {
                return url.absoluteString
            }
            
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.query = nil
            return components?.url?.absoluteString ?? ""
        }
    }
    
    public var body: some View {
        @Bindable var navigation = navigation
        TabView(selection: $navigation.selectedTab) {
            Group {
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
            .toolbar {
                if !network.isConnected {
                    ToolbarItem(placement: .status) {
                        Label("Offline", systemImage: "wifi.slash")
                            .labelStyle(.titleAndIcon)
                            .imageScale(.small)
                    }
                }
            }
        }
        #if !os(visionOS)
        .tint(tint)
        #endif
        .modifier(AuthHandlerViewModifier())
        .modifier(ToastViewModifier())
        .task(intent: FetchDeviceInfoIntent())
        
    }
}

#Preview {
    ContentView()
}
