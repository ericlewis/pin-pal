import Foundation
import Get

final class ClientDelegate: APIClientDelegate {

    private let userDefaults: UserDefaults = .init(suiteName: "group.com.ericlewis.Pin-Pal") ?? .standard

    private var accessToken: String?  {
        didSet {
            userDefaults.setValue(accessToken, forKey: Constants.ACCESS_TOKEN)
        }
    }
    
    var userId: UUID?  {
        didSet {
            userDefaults.setValue(userId?.uuidString, forKey: Constants.USER_ID)
        }
    }
    
    init() {
        self.accessToken = userDefaults.string(forKey: Constants.ACCESS_TOKEN)
        if let d = userDefaults.string(forKey: Constants.USER_ID), let userId = UUID(uuidString: d) {
            self.userId = userId
        }
    }
    
    func client(_ client: APIClient, shouldRetry task: URLSessionTask, error: Error, attempts: Int) async throws -> Bool {
        if case .unacceptableStatusCode(let statusCode) = error as? Get.APIError, statusCode == 403, attempts < 3 {
            let result = try await client.send(API.session()).value
            accessToken = result.accessToken
            userId = result.user.id
            return true
        }
        return false
    }
    
    func client(_ client: APIClient, willSendRequest request: inout URLRequest) async throws {
        guard let accessToken else { return }
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }
}
