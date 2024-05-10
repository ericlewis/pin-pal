import Foundation

public struct Session: Codable {
    public let user: User
    public let accessToken: String
    let expires: Date
}
