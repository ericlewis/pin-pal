import Foundation

struct MusicEvent: Codable {
    let artistName: String?
    let albumName: String?
    let trackTitle: String?
    let prompt: String?
    let sourceService: String
}

struct AiMicEvent: Codable {
    let request: String
    let response: String
}

struct TranslationEvent: Codable {
    let targetLanguage: String
    let originLanguage: String
}

struct CallEvent: Codable {
    struct Peer: Codable {
        let displayName: String
        let phoneNumber: String
    }
    
    let duration: Duration?
    let peers: [Peer]
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.peers = try container.decode([Peer].self, forKey: .peers)
        if let durationSeconds = try container.decodeIfPresent(Double.self, forKey: .durationSeconds) {
            self.duration = .seconds(durationSeconds)
        } else {
            self.duration = nil
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.duration, forKey: .durationSeconds)
        try container.encode(self.peers, forKey: .peers)
    }
    
    enum CodingKeys: CodingKey {
        case durationSeconds
        case peers
    }
}

enum EventDataEnvelope: Codable {
    case aiMic(AiMicEvent)
    case music(MusicEvent)
    case call(CallEvent)
    case translation(TranslationEvent)
    case unknown
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let aiMicEvent = try? container.decode(AiMicEvent.self) {
            self = .aiMic(aiMicEvent)
        } else if let musicEvent = try? container.decode(MusicEvent.self) {
            self = .music(musicEvent)
        } else if let callEvent = try? container.decode(CallEvent.self) {
            self = .call(callEvent)
        } else if let translationEvent = try? container.decode(TranslationEvent.self) {
            self = .translation(translationEvent)
        } else {
            self = .unknown
        }
    }
}

public struct EventContentEnvelope: Codable {
    let originatorIdentifier: String
    let feedbackUUID: UUID?
    let eventCreationTime: Date
    let feedbackCategory: String?
    let eventType: String
    let eventIdentifier: UUID
    let eventData: EventDataEnvelope
}

public struct Sort: Codable {
    let empty: Bool
    let sorted: Bool
    let unsorted: Bool
}

public struct Pageable: Codable {
    let unpaged: Bool
    let pageNumber: Int
    let offset: Int
    let sort: Sort
    let pageSize: Int
    let paged: Bool
}

public struct Thumbnail: Codable {
    let fileUUID: UUID
    let accessToken: String
}

struct Video: Codable {
    let fileUUID: UUID
    let accessToken: String
}

enum CaptureType: String, Codable {
    case photo = "PHOTO"
    case video = "VIDEO"
}

public struct CaptureEnvelope: Codable {
    let uuid: UUID
    let type: CaptureType
    let thumbnail: Thumbnail
    let video: Video?
}

public struct ContentEnvelope: Codable {
    enum DataClass: Codable {
        case capture(CaptureEnvelope)
        case note(Note)
        case unknown
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            if let note = try? container.decodeIfPresent(Note.self, forKey: .note) {
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
    }
    
    let uuid: UUID
    let originClientId: String
    let favorite: Bool
    let userLastModified: Date
    let userCreatedAt: Date
    
    var data: DataClass
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
  
        self.uuid = try container.decode(UUID.self, forKey: .uuid)
        self.data = try container.decode(DataClass.self, forKey: .data)
        self.userLastModified = try container.decode(Date.self, forKey: .userLastModified)
        self.userCreatedAt = try container.decode(Date.self, forKey: .userCreatedAt)
        self.originClientId = try container.decode(String.self, forKey: .originClientId)
        self.favorite = try container.decode(Bool.self, forKey: .favorite)
        
        if case var .note(note) = self.data {
            note.memoryId = self.uuid
            self.data = .note(note)
        }
    }
    
    enum CodingKeys: CodingKey {
        case uuid
        case data
        case userLastModified
        case userCreatedAt
        case originClientId
        case favorite
    }
}

extension ContentEnvelope {
    func get() -> Note? {
        switch data {
        case let .note(note): note
        default: nil
        }
    }
    
    func get() -> CaptureEnvelope? {
        switch data {
        case let .capture(capture): capture
        default: nil
        }
    }
}

public struct PageableContentEnvelope<C: Codable>: Codable {
    let number: Int
    let content: [C]
    let pageable: Pageable
    let sort: Sort
    let numberOfElements: Int
    let totalPages: Int
    let size: Int
    let last: Bool
    let empty: Bool
    let totalElements: Int
    let first: Bool
}

public typealias PageableMemoryContentEnvelope = PageableContentEnvelope<ContentEnvelope>
public typealias PageableEventContentEnvelope = PageableContentEnvelope<EventContentEnvelope>
