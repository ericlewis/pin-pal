import Foundation

public struct SmartGeneratedPlaylist: Codable {
    static let decoder = JSONDecoder()
    
    struct Track: Codable {
        let title: String
        let artists: [String]
        
        init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.title = try container.decode(String.self, forKey: .title)
            let artistsData = try container.decode(String.self, forKey: .artists)
            self.artists = artistsData.dropFirst().dropLast().split(separator: ", ").map({ String($0) })
        }
        
        enum CodingKeys: CodingKey {
            case title
            case artists
        }
    }
    
    let tracks: [Track]
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let tracksData = try container.decode(String.self, forKey: .tracks).data(using: .utf8) else {
            self.tracks = []
            return
        }
        self.tracks = try Self.decoder.decode([Track].self, from: tracksData)
    }
}

public struct MusicEvent: Codable {
    let artistName: String?
    let albumName: String?
    let trackTitle: String?
    let prompt: String?
    let albumArtUuid: UUID?
    let length: String? // number of tracks
    let generatedPlaylist: SmartGeneratedPlaylist?
    let sourceService: String
    let trackID: String?
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.artistName = try container.decodeIfPresent(String.self, forKey: .artistName)
        self.albumName = try container.decodeIfPresent(String.self, forKey: .albumName)
        self.trackTitle = try container.decodeIfPresent(String.self, forKey: .trackTitle)
        self.prompt = try container.decodeIfPresent(String.self, forKey: .prompt)
        self.albumArtUuid = try container.decodeIfPresent(UUID.self, forKey: .albumArtUuid)
        self.length = try container.decodeIfPresent(String.self, forKey: .length)
        self.sourceService = try container.decode(String.self, forKey: .sourceService)
        self.trackID = try container.decodeIfPresent(String.self, forKey: .trackID)
        guard let playlistData = try container.decodeIfPresent(String.self, forKey: .generatedPlaylist)?.data(using: .utf8) else {
            self.generatedPlaylist = nil
            return
        }
        self.generatedPlaylist = try JSONDecoder().decode(SmartGeneratedPlaylist.self, from: playlistData)
    }
}

public struct AiMicEvent: Codable {
    public let request: String
    public let response: String
}

public struct TranslationEvent: Codable {
    let targetLanguage: String
    let originLanguage: String
}

public struct CallEvent: Codable {
    struct Peer: Codable {
        let displayName: String
        let phoneNumber: String
    }
    
    let duration: Duration?
    let peers: [Peer]
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.peers = try container.decode([Peer].self, forKey: .peers)
        if let durationSeconds = try container.decodeIfPresent(Double.self, forKey: .durationSeconds) {
            self.duration = .seconds(durationSeconds)
        } else {
            self.duration = nil
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.duration, forKey: .durationSeconds)
        try container.encode(self.peers, forKey: .peers)
    }
    
    enum CodingKeys: CodingKey {
        case durationSeconds
        case peers
    }
}

public enum EventDataEnvelope: Codable {
    case aiMic(AiMicEvent)
    case music(MusicEvent)
    case call(CallEvent)
    case translation(TranslationEvent)
    case unknown
    
    public init(from decoder: any Decoder) throws {
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
    public let eventCreationTime: Date
    let feedbackCategory: String?
    let eventType: String
    public let eventIdentifier: UUID
    public let eventData: EventDataEnvelope
}

extension EventContentEnvelope: Identifiable {
    public var id: UUID { eventIdentifier }
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

public struct FileAsset: Codable, Hashable {
    public let fileUUID: UUID
    public let accessToken: String
}

public struct Video: Codable, Hashable {
    public let fileUUID: UUID
    public let accessToken: String
}

enum CaptureType: String, Codable, Hashable {
    case photo = "PHOTO"
    case video = "VIDEO"
}

enum CaptureState: String, Codable, Hashable {
    case pending = "PENDING_UPLOAD"
    case processed = "PROCESSED"
    case processing = "PROCESSING"
    
    var title: String {
        switch self {
        case .pending:
            "Pending upload"
        case .processed:
            "Processed"
        case .processing:
            "Processing"
        }
    }
}

public struct CaptureEnvelope: Codable, Hashable {
    let uuid: UUID
    let type: CaptureType
    public let thumbnail: FileAsset
    public var memoryId: UUID?
    public let video: Video?
    
    let originalThumbnails: [FileAsset]?
    public let originals: [FileAsset]?
    public let derivatives: [FileAsset]?
    let location: String?
    let latitude: Double?
    let longitude: Double?
    let state: CaptureState
}

public struct ContentEnvelope: Codable, Identifiable, Hashable {
    enum DataClass: Codable, Hashable {
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
    var favorite: Bool
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

extension ContentEnvelope {
    public func get() -> Note? {
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

public struct PageableContentEnvelope<C: Codable>: Codable {
    let number: Int
    public var content: [C]
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
