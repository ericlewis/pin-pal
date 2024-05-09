import SwiftData
import Foundation

@Model
public class _Note {
    
    @Attribute(.unique)
    public let uuid: UUID
    public let parentUUID: UUID
    
    public let name: String
    public let body: String
    
    public let isFavorite: Bool
    
    public let createdAt: Date
    public let modifiedAt: Date
    
    public init(uuid: UUID, parentUUID: UUID, name: String, body: String, isFavorite: Bool, createdAt: Date, modifedAt: Date) {
        self.uuid = uuid
        self.parentUUID = parentUUID
        self.name = name
        self.body = body
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.modifiedAt = modifedAt
    }
}

extension _Note {
    public static func all(order: SortOrder = .reverse) -> FetchDescriptor<_Note> {
        FetchDescriptor<_Note>(sortBy: [.init(\.createdAt, order: order)])
    }
}

