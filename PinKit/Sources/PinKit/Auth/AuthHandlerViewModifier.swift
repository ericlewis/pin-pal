import SwiftUI

public struct AuthHandlerViewModifier: ViewModifier {
    
    @Environment(Navigation.self)
    private var navigation
    
    @Environment(HumaneCenterService.self)
    private var api
    
    @AppStorage("wtf")
    private var a: Int = 0
    
    @State
    private var authenticationWebView = AuthenticationWebViewModel()
    
    public init() {}
    
    public func body(content: Content) -> some View {
        @Bindable var navigation = navigation
        @Bindable var webView = authenticationWebView
        content
            .sheet(isPresented: $navigation.authenticationPresented) {
                AuthenticationWebView()
                    .ignoresSafeArea()
                    .environment(webView)
                    .onAppear {
                        webView.load(url: URL(string: "https://humane.center/")!)
                        webView.dismissed = {
                            self.navigation.authenticationPresented = false
                            a = 1337
                        }
                    }
                    .interactiveDismissDisabled()
            }
            .onAppear {
                
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
