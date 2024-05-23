import SwiftData
import Foundation

public typealias Note = SchemaV1._Note__

extension SchemaV1 {
    
    @Model
    public class _Note__ {
        
        @Attribute(.unique)
        public let uuid: UUID
        
        @Attribute(.unique)
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
    
}

extension Note {
    public static func all(order: SortOrder = .reverse) -> FetchDescriptor<Note> {
        FetchDescriptor<Note>(sortBy: [.init(\.createdAt, order: order)])
    }
}

