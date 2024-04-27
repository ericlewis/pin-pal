import SwiftUI
import WebKit
import OSLog

@Observable class AuthenticationWebViewModel {
    
    private var webView: WKWebView?
    private var logger = Logger(subsystem: "WebViewModel", category: "model")
    private var coordinator: Coordinator!
    
    var dismissed: (() -> Void)?
    
    init() {
        self.coordinator = Coordinator(parent: self)
    }
    
    func makeView() -> WKWebView {
        let view = WKWebView()
        view.navigationDelegate = self.coordinator
        self.webView = view
        return view
    }
    
    func load(url: URL) {
        self.webView?.load(URLRequest(url: url))
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        
        var parent: AuthenticationWebViewModel
        
        init(parent: AuthenticationWebViewModel) {
            self.parent = parent
        }
        
        @MainActor
        func webView(_ webView: WKWebView, decidePolicyFor navigationResponse: WKNavigationResponse) async -> WKNavigationResponsePolicy {
            let cookies = await webView.configuration.websiteDataStore.httpCookieStore.allCookies()
            for cookie in cookies {
                self.parent.logger.debug("syncing cookie: \(cookie.name)")
                URLSession.shared.configuration.httpCookieStorage?.setCookie(cookie)
            }
            if navigationResponse.response.url == URL(string: "https://humane.center/") {
                self.parent.dismissed?()
            }
            return .allow
        }
    }
}

struct AuthenticationWebView: UIViewRepresentable {
    
    @Environment(AuthenticationWebViewModel.self)
    private var model
    
    func makeUIView(context: Context) -> some UIView {
        model.makeView()
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {}
}

#Preview {
    AuthenticationWebView()
}
