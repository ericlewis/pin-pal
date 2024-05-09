import Foundation

public struct Note: Codable, Hashable, Equatable {
    
    public var uuid: UUID? = nil
    public var text: String
    public var title: String
    
    public var memoryId: UUID? = nil
    public var createdAt: Date? = nil
    public var modifiedAt: Date? = nil

    public static func create() -> Note {
        Note(text: "", title: "")
    }
    
    public init(uuid: UUID? = nil, memoryId: UUID? = nil, text: String, title: String, createdAt: Date = .now, modifedAt: Date = .now) {
        self.uuid = uuid
        self.memoryId = memoryId
        self.text = text
        self.title = title
        self.createdAt = createdAt
        self.modifiedAt = modifedAt
    }
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try container.decodeIfPresent(UUID.self, forKey: .uuid)
        self.text = try container.decode(String.self, forKey: .text)
        self.title = try container.decode(String.self, forKey: .title)
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let uuid {
            try container.encode(uuid, forKey: .uuid)
        }
        try container.encode(text, forKey: .text)
        try container.encode(title, forKey: .title)
    }
    
    enum CodingKeys: CodingKey {
        case uuid
        case text
        case title
    }
}

extension Note: Identifiable {
    public var id: UUID? { uuid }
}
