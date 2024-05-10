import Foundation
import Get

final class ClientDelegate: APIClientDelegate {

    private let userDefaults: UserDefaults = .init(suiteName: "group.com.ericlewis.Pin-Pal") ?? .standard

    private var accessToken: String?  {
        didSet {
            userDefaults.setValue(accessToken, forKey: Constants.ACCESS_TOKEN)
        }
    }
    
    init() {
        self.accessToken = userDefaults.string(forKey: Constants.ACCESS_TOKEN)
    }
    
    func client(_ client: APIClient, shouldRetry task: URLSessionTask, error: Error, attempts: Int) async throws -> Bool {
        if case .unacceptableStatusCode(let statusCode) = error as? Get.APIError, statusCode == 403, attempts < 3 {
            accessToken = try await client.send(API.session()).value.accessToken
            return true
        }
        return false
    }
    
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) async throws {
        guard let accessToken else { return }
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }
}
