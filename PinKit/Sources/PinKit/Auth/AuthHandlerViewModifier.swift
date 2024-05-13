import SwiftUI

public struct AuthHandlerViewModifier: ViewModifier {
    
    @Environment(Navigation.self)
    private var navigation
    
    @Environment(HumaneCenterService.self)
    private var api
    
    @Environment(AppState.self)
    private var app
    
    @Environment(\.database)
    private var database
    
    @State
    private var authenticationWebView = AuthenticationWebViewModel()
    
    public init() {}
    
    public func body(content: Content) -> some View {
        @Bindable var navigation = navigation
        @Bindable var webView = authenticationWebView
        content
            .sheet(isPresented: $navigation.authenticationPresented, onDismiss: {
                Task {
                    let intent = SyncNotesIntent()
                    intent.database = database
                    intent.service = api
                    intent.app = app
                    try await intent.perform()
                }
            }) {
                AuthenticationWebView()
                    .ignoresSafeArea()
                    .environment(webView)
                    .onAppear {
                        webView.load(url: URL(string: "https://humane.center/")!)
                        webView.dismissed = {
                            self.navigation.authenticationPresented = false
                        }
                    }
                    .interactiveDismissDisabled()
            }
            .task {
                self.navigation.authenticationPresented = !api.isLoggedIn()
                do {
                    let _ = try await api.deviceIdentifiers()
                } catch is CancellationError {
                    
                } catch {
                    self.navigation.authenticationPresented = true
                }
            }
    }
}
