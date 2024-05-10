import Foundation

public struct Session: Codable {
    public let accessToken: String
    let expires: Date
}
