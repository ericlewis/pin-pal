import SwiftUI

public struct AuthHandlerViewModifier: ViewModifier {
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(HumaneCenterService.self)
    private var api
    
    @State
    private var authenticationWebView = AuthenticationWebViewModel()
    
    public init() {}
    
    public func body(content: Content) -> some View {
        @Bindable var navigationStore = navigationStore
        @Bindable var webView = authenticationWebView
        content
            .sheet(isPresented: $navigationStore.authenticationPresented) {
                AuthenticationWebView()
                    .ignoresSafeArea()
                    .environment(webView)
                    .onAppear {
                        webView.load(url: URL(string: "https://humane.center/")!)
                        webView.dismissed = {
                            self.navigationStore.authenticationPresented = false
                        }
                    }
                    .interactiveDismissDisabled()
            }
            .onAppear {
                self.navigationStore.authenticationPresented = !api.isLoggedIn()
            }
    }
}
