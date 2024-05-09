import SwiftData
import Foundation

enum HumaneCloudOrigin {
    case aiBus(String)
}

enum HumaneExperienceOrigin: String {
    case answers = "humane.experience.answers"
    case dialer = "humane.experience.dialer"
    case messages = "humane.experience.messages"
    case music = "humane.experience.music"
    case notifications = "humane.experience.notifications"
    case photography = "humane.experience.photography"
    case systemNavigation = "humane.experience.systemnavigation"
    case translation = "humane.experience.translation"
}

enum HumaneOrigin {
    case cloud(HumaneCloudOrigin)
    case experience(HumaneExperienceOrigin)
}

enum Origin: Codable, CustomStringConvertible {
    var description: String {
        switch self {
        case let .unknown(value): value
        case let .humane(.cloud(.aiBus(value))): value
        case let .humane(.experience(value)): value.rawValue
        }
    }
    
    case humane(HumaneOrigin)
    case unknown(String)
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let originString = try container.decode(String.self)
        if originString.starts(with: "humane.cloud.aiBus") {
            self = .humane(.cloud(.aiBus(originString)))
        } else if originString.starts(with: "humane.experience"), let origin = HumaneExperienceOrigin(rawValue: originString) {
            self = .humane(.experience(origin))
        } else {
            self = .unknown(originString)
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        
    }
}

enum HumaneEventType: String {
    case capture = "humane.capture"
    case catchMeUp = "humane.catchMeUp"
    case createNote = "humane.createNote"
    case endCall = "humane.endCall"
    case missedCall = "humane.missedCall"
    case nearby = "humane.nearby"
    case playMusicTrack = "humane.playMusicTrack"
    case playSmartPlaylist = "humane.playSmartPlaylist"
    case receiveMessage = "humane.receiveMessage"
    case respond = "humane.respond"
    case sendMessage = "humane.sendMessage"
    case translation = "humane.translation"
    case updateNote = "humane.updateNote"
}

enum EventType: Codable, CustomStringConvertible {
    case humane(HumaneEventType)
    case unknown(String)
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let typeString = try container.decode(String.self)
        if typeString.starts(with: "humane"), let event = HumaneEventType(rawValue: typeString) {
            self = .humane(event)
        } else {
            self = .unknown(typeString)
        }
    }
    
    func encode(to encoder: any Encoder) throws {
        
    }
    
    var description: String {
        switch self {
        case let .humane(event): event.rawValue
        case let .unknown(event): event
        }
    }
}

struct EventData: Codable {
    let noteId: UUID?
    let memoryId: UUID?
    let memoryUUID: UUID?
}

struct Event: Codable {
    let eventIdentifier: UUID
    let eventCreationTime: Date
    let originatorIdentifier: Origin
    let eventType: EventType
    let feedbackUUID: UUID?
    let feedbackCategory: String?
}

public struct EventStream: Codable {
    let content: [Event]
}

@Model
class _Capture {
    var uuid: UUID
    let parentUUID: UUID
    
    let thumbnailUUID: UUID
    let thumbnailAccessToken: UUID
    
    init(uuid: UUID, parentUUID: UUID, thumbnailUUID: UUID, thumbnailAccessToken: UUID) {
        self.uuid = uuid
        self.parentUUID = parentUUID
        self.thumbnailUUID = thumbnailUUID
        self.thumbnailAccessToken = thumbnailAccessToken
    }
}

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
