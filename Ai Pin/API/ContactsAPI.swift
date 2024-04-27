import Foundation
import WebKit

enum ContactsAPIError: Error {
    case dataError
}

@Observable class ContactsAPI: NSObject, WKNavigationDelegate {
    static let shared = ContactsAPI()
    
    private var webView: WKWebView?
    private(set) var isReady = false
    
    override init() {
        super.init()
    }
    
    func prepare() {
        self.webView = WKWebView()
        self.webView?.isInspectable = true
        self.webView?.navigationDelegate = self
        self.webView?.load(.init(url: URL(string: "https://humane.center/contacts")!))
    }

    func contacts() async throws -> [Contact] {
        let result = try await self.webView?.callAsyncJavaScript("""
        return JSON.stringify(JSON.parse(self.__next_f.find(([,a]) => a?.includes("{\\"contacts\\":[{\\"id\\":\\""))[1].slice(2))[3]);
""", contentWorld: .page)
        guard let str = result as? String, let data = str.data(using: .utf8) else {
            throw ContactsAPIError.dataError
        }
        let decoded = try JSONDecoder().decode(ContactsResponse.self, from: data)
        let _ = await MainActor.run { self.webView?.loadHTMLString("", baseURL: nil) }
        return decoded.contacts
    }
    
    @MainActor
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if webView.url?.path() == "/contacts" {
            isReady = true
        }
    }
}
