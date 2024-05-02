import Foundation

public enum HumaneCloudOrigin {
    case aiBus(String)
}

public enum HumaneExperienceOrigin: String {
    case answers = "humane.experience.answers"
    case dialer = "humane.experience.dialer"
    case messages = "humane.experience.messages"
    case music = "humane.experience.music"
    case notifications = "humane.experience.notifications"
    case photography = "humane.experience.photography"
    case systemNavigation = "humane.experience.systemnavigation"
    case translation = "humane.experience.translation"
}

public enum HumaneOrigin {
    case cloud(HumaneCloudOrigin)
    case experience(HumaneExperienceOrigin)
}

public enum Origin: Codable, CustomStringConvertible {
    public var description: String {
        switch self {
        case let .unknown(value): value
        case let .humane(.cloud(.aiBus(value))): value
        case let .humane(.experience(value)): value.rawValue
        }
    }
    
    case humane(HumaneOrigin)
    case unknown(String)
    
    public init(from decoder: any Decoder) throws {
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
    
    public func encode(to encoder: any Encoder) throws {
        
    }
}

public enum HumaneEventType: String {
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

public enum EventType: Codable, CustomStringConvertible {
    case humane(HumaneEventType)
    case unknown(String)
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let typeString = try container.decode(String.self)
        if typeString.starts(with: "humane"), let event = HumaneEventType(rawValue: typeString) {
            self = .humane(event)
        } else {
            self = .unknown(typeString)
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        
    }
    
    public var description: String {
        switch self {
        case let .humane(event): event.rawValue
        case let .unknown(event): event
        }
    }
}
public struct Event: Codable {
    public let eventIdentifier: UUID
    public let eventCreationTime: Date
    public let originatorIdentifier: Origin
    public let eventType: EventType
    public let feedbackUUID: UUID?
    public let feedbackCategory: String?
}

public struct EventStream: Codable {
    public let content: [Event]
}

