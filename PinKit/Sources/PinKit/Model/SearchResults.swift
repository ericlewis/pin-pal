import Foundation

public struct SearchResults: Codable {
    public struct Result: Codable {
        public let uuid: UUID
    }
    
    public let memories: [Result]
}
