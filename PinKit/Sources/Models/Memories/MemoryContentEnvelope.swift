import Foundation

public struct MemoryContentEnvelope: Codable, Identifiable, Hashable {
    enum DataClass: Codable, Hashable {
        case capture(CaptureEnvelope)
        case note(NoteEnvelope)
        case unknown
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let note = try? container.decodeIfPresent(NoteEnvelope.self, forKey: .note) {
                self = .note(note)
            } else if let s = try? decoder.singleValueContainer(), let capture = try? s.decode(CaptureEnvelope.self) {
                self = .capture(capture)
            } else {
                self = .unknown
            }
        }
        
        func encode(to encoder: any Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            if case let .note(note) = self {
                try container.encode(note, forKey: .note)
            } else if case let .capture(capture) = self {
                try container.encode(capture, forKey: .thumbnail)
            }
        }
        
        enum CodingKeys: CodingKey {
            case note
            case thumbnail
        }
        
        func hash(into hasher: inout Hasher) {
            switch self {
            case .capture(let captureEnvelope):
                hasher.combine(captureEnvelope)
            case .note(let note):
                hasher.combine(note)
            case .unknown:
                hasher.combine("unknown")
            }
        }
    }
    
    public let id: UUID
    let uuid: UUID
    let originClientId: String
    public var favorite: Bool
    public let userLastModified: Date
    public let userCreatedAt: Date
    let location: String?
    
    var data: DataClass
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        let id = try container.decode(UUID.self, forKey: .uuid)
        self.id = id
        self.uuid = id
        self.data = try container.decode(DataClass.self, forKey: .data)
        self.userLastModified = try container.decode(Date.self, forKey: .userLastModified)
        self.userCreatedAt = try container.decode(Date.self, forKey: .userCreatedAt)
        self.originClientId = try container.decode(String.self, forKey: .originClientId)
        self.favorite = try container.decode(Bool.self, forKey: .favorite)
        self.location = try container.decodeIfPresent(String.self, forKey: .location)

        if case var .note(note) = self.data {
            note.memoryId = self.uuid
            note.createdAt = self.userCreatedAt
            note.modifiedAt = self.userLastModified
            self.data = .note(note)
        } else if case var .capture(capture) = self.data {
            capture.memoryId = self.uuid
            self.data = .capture(capture)
        }
    }
    
    enum CodingKeys: CodingKey {
        case uuid
        case data
        case userLastModified
        case userCreatedAt
        case originClientId
        case favorite
        case location
    }
}

extension MemoryContentEnvelope {
    public func get() -> NoteEnvelope? {
        switch data {
        case let .note(note): note
        default: nil
        }
    }
    
    public func get() -> CaptureEnvelope? {
        switch data {
        case let .capture(capture): capture
        default: nil
        }
    }
}
