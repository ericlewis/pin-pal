import Foundation

public struct RemoteNote: Codable, Equatable {
    var uuid: UUID?
    var text: String
    var title: String
    
    var memoryId: UUID? = nil
    
    public static func create() -> RemoteNote {
        RemoteNote(text: "", title: "")
    }
    
    public init(uuid: UUID? = nil, memoryId: UUID? = nil, text: String, title: String) {
        self.uuid = uuid
        self.memoryId = memoryId
        self.text = text
        self.title = title
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
    
    public static func == (lhs: RemoteNote, rhs: RemoteNote) -> Bool {
        lhs.uuid == rhs.uuid && lhs.title == rhs.title && lhs.text == rhs.text
    }
}

extension RemoteNote: Identifiable {
    public var id: UUID? { uuid }
}
