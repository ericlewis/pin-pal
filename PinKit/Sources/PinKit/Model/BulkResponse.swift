import Foundation

public struct BulkResponse: Codable {
    public let memoryUUIDToStatus: [String: Int]
}
