import Foundation

public struct BulkMemoryActionResult: Codable {
    public let memoryUUIDToStatus: [String: Int]
}
