import SwiftUI

struct HeadlessCookieRefreshKey: EnvironmentKey {
    static var defaultValue: HeadlessCookieRefreshAction = .init(action: {})
}

public struct HeadlessCookieRefreshAction {
    let action: () -> Void
    
    public func callAsFunction() {
        
    }
}

extension EnvironmentValues {
    var _expensiveTokenRefresh: HeadlessCookieRefreshAction {
        get { self[HeadlessCookieRefreshKey.self] }
        set { self[HeadlessCookieRefreshKey.self] = newValue }
    }
}

extension EnvironmentValues {
    public var expensiveTokenRefresh: HeadlessCookieRefreshAction {
        get { _expensiveTokenRefresh }
    }
}

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
            .environment(\._expensiveTokenRefresh, .init(action: headlessRefresh))
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
    
    func headlessRefresh() {
        // var view = authenticationWebView.makeView()
        print("tata")
    }
}
