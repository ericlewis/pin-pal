import Foundation
import AnyCodable

// STATE: PENDING UPLOAD

// MARK: API

struct DetailedDeviceInfo {
    let id: String
    let iccid: String
    let serialNumber: String
    let sku: String
    let color: String
}

enum Domain: String {
    case captures = "CAPTURE"
    case notes = "NOTE"
    
    case aiMic = "Ai Mic"
    case calls = "Calls"
    case translation = "Translation"
    case music = "Music"
}

struct PaymentMethod: Codable {
    let last4: String
    let brand: String
    let source: String
}

struct Subscription: Codable {
    let status: String
    let phoneNumber: String
    let accountNumber: String
    let planType: String
    let defaultPaymentMethod: PaymentMethod
    let pinSetAt: Date?
    let planPrice: Int
}

struct EventContent: Codable {
    let originatorIdentifier: String
    let feedbackUUID: UUID?
    let eventCreationTime: Date
    let feedbackCategory: String?
    let eventType: String
    let eventIdentifier: UUID
    let eventData: [String: AnyCodable]
}

struct Sort: Codable {
    let empty: Bool
    let sorted: Bool
    let unsorted: Bool
}

struct Pageable: Codable {
    let unpaged: Bool
    let pageNumber: Int
    let offset: Int
    let sort: Sort
    let pageSize: Int
    let paged: Bool
}

struct Thumbnail: Codable {
    let fileUUID: UUID
    let accessToken: String
}

struct Capture: Codable {
    let uuid: String
    let data: DataClass
    let userLastModified: Date
    let userCreatedAt: Date
    let originClientId: String
    let favorite: Bool
    
    // MARK: - DataClass
    struct DataClass: Codable {
        let type: String
        let uuid: UUID
        let createdAt: Date
        let state: String
        
        let thumbnail: Thumbnail?
//        let location: String
//        let latitude: String
//        let longitude: String
    }
}

struct CapturesResponseContainer: Codable {
    let number: Int
    let content: [Capture]
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

struct NotesResponseContainer: Codable {
    let number: Int
    let content: [Memory]
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

struct ResponseContainer: Codable {
    let number: Int
    let content: [EventContent]
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

@Observable class Note: Codable, Equatable {
    var uuid: UUID? = nil
    var text: String
    var title: String
    
    var memoryId: UUID? = nil
    
    static func create() -> Note {
        Note(text: "", title: "")
    }
    
    init(uuid: UUID? = nil, text: String, title: String) {
        self.uuid = uuid
        self.text = text
        self.title = title
    }
    
    required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uuid = try container.decodeIfPresent(UUID.self, forKey: .uuid)
        self.text = try container.decode(String.self, forKey: .text)
        self.title = try container.decode(String.self, forKey: .title)
    }
    
    func encode(to encoder: any Encoder) throws {
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
    
    static func == (lhs: Note, rhs: Note) -> Bool {
        lhs.uuid == rhs.uuid && lhs.title == rhs.title && lhs.text == rhs.text
    }
}

extension Note: Identifiable {
    var id: UUID? { uuid }
}

struct EventOverview: Decodable {
    struct Counts: Codable {
        let todayCount: Int
        let totalCount: Int
    }
    
    enum CodingKeys: CodingKey {
        case overview
    }
    
    enum AdditionalCodingKeys: String, CodingKey {
        case photos = "Photos"
        case mic = "Ai Mic"
        case calls = "Calls"
        case notes = "Notes"
        case messages = "Messages"
        case translation = "Translation"
        case music = "Music"
    }
    
    let photos: Counts
    let mic: Counts
    let calls: Counts
    let notes: Counts
    let messages: Counts
    let translation: Counts
    let music: Counts

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let overviewContainer = try container.nestedContainer(keyedBy: AdditionalCodingKeys.self, forKey: .overview)
        self.photos = try overviewContainer.decode(Counts.self, forKey: .photos)
        self.mic = try overviewContainer.decode(Counts.self, forKey: .mic)
        self.calls = try overviewContainer.decode(Counts.self, forKey: .calls)
        self.notes = try overviewContainer.decode(Counts.self, forKey: .notes)
        self.messages = try overviewContainer.decode(Counts.self, forKey: .messages)
        self.translation = try overviewContainer.decode(Counts.self, forKey: .translation)
        self.music = try overviewContainer.decode(Counts.self, forKey: .music)
    }
}

struct Session: Codable {
    let accessToken: String
}

struct Addon: Codable {
    let provisionedSuccessfully: Bool?
    let price: Int?
    let name: String
    let provisioningStatus: String?
    let days: Int?
    let dataThrottling: Double?
    let displayName, spid, optionType: String
    let oneTimeAddon: Bool
    let timeToLiveInDays: Int
    let billingCycle: String?
    let auxiliaryBundles: [String]?
}

// TODO: these are not strings lol
struct MemoriesResponse: Codable {
    let aiSessions: [Memory]?
    let photoCollections: [Memory]?
    let aiDJEvents: [Memory]?
    let photos: [Memory]?
    let videos: [Memory]?
    let playTrackEvents: [Memory]?
    let notes: [Memory]?
    let phoneCalls: [Memory]?
    let messages: [Memory]?
}

struct Memory: Codable, Equatable {
    let uuid: UUID
    var data: DataClass
    let userLastModified: Date
    let userCreatedAt: Date
    let originClientId: String
    let favorite: Bool
    
    // MARK: - DataClass
    struct DataClass: Codable, Equatable {
        let type: String
        let uuid: UUID
        let createdAt: Date
        let lastModifiedAt: Date
        let state: String
        
        let note: Note?
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
  
        self.uuid = try container.decode(UUID.self, forKey: .uuid)
        self.data = try container.decode(DataClass.self, forKey: .data)
        self.userLastModified = try container.decode(Date.self, forKey: .userLastModified)
        self.userCreatedAt = try container.decode(Date.self, forKey: .userCreatedAt)
        self.originClientId = try container.decode(String.self, forKey: .originClientId)
        self.favorite = try container.decode(Bool.self, forKey: .favorite)
        self.data.note?.memoryId = self.uuid
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

struct LostDeviceResponse: Codable {
    let isLost: Bool
    let deviceId: String
}

struct FeatureFlagResponse: Codable {
    enum State: String, Codable {
        case enabled
        case disabled
    }
    
    let state: State
    var bool: Bool {
        switch state {
        case .enabled: true
        case .disabled: false
        }
    }
}

// MARK: ContactsAPI

struct Contact: Decodable {
    let id: UUID
    let displayName: String?
}

struct ContactsResponse: Decodable {
    let contacts: [Contact]
}
