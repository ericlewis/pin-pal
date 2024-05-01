import SwiftData
import Foundation

//"eventData": {
//      "noteId": "f660d8d2-8ab5-40ce-b517-aec633cdf7b3",
//      "text": "Testing",
//      "memoryUUID": "182467d4-72db-4065-a49a-bd8b39d71be6"
//    },

//{
//  "eventIdentifier": "c7593988-087a-4a50-ad65-c42e84b1cb7a",
//  "originatorIdentifier": "humane.experience.photography",
//  "eventCreationTime": "2024-04-25T19:31:03.541031Z",
//  "eventData": {
//    "memoryId": "14874160-5c35-4b48-b90d-3f483682aafe",
//    "type": "PHOTO"
//  },
//  "eventType": "humane.capture",
//  "feedbackUUID": null,
//  "feedbackCategory": null
//},

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

struct SyncEngine {
    
}

@Model
class _Note {
    var uuid: UUID? = nil
    var title: String
    var text: String
    
    init(uuid: UUID? = nil, title: String, text: String) {
        self.uuid = uuid
        self.text = text
        self.title = title
    }
    
    init(from note: Note) {
        self.uuid = note.id
        self.title = note.title
        self.text = note.text
    }
}

@Model
class _Capture {
    var uuid: UUID? = nil

    init(uuid: UUID? = nil) {
        self.uuid = uuid
    }
}

@Model
class _Memory {
    let uuid: UUID
    let origin: String
    var isFavorited: Bool
    let lastModifiedAt: Date
    let createdAt: Date
    
    var note: _Note?
    var capture: _Capture?
    
    init(uuid: UUID, origin: String, isFavorited: Bool, lastModifiedAt: Date, createdAt: Date, note: _Note? = nil, capture: _Capture? = nil) {
        self.uuid = uuid
        self.origin = origin
        self.isFavorited = isFavorited
        self.lastModifiedAt = lastModifiedAt
        self.createdAt = createdAt
        self.note = note
        self.capture = capture
    }
}

@Model
class _Event {
    let uuid: UUID
    
    init(uuid: UUID) {
        self.uuid = uuid
    }
}
