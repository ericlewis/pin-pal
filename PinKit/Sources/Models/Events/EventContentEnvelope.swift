import Foundation

public enum FeedbackCategory: String, Codable {
    case positive = "EVENT_FEEDBACK_CATEGORY_POSITIVE"
    case negative = "EVENT_FEEDBACK_CATEGORY_NEGATIVE"
}

public struct EventContentEnvelope: Codable {
    
    public enum DataEnvelope: Codable {
        case aiMic(RemoteAiMicEvent)
        case music(RemoteMusicEvent)
        case call(RemoteCallEvent)
        case translation(RemoteTranslationEvent)
        case unknown
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let aiMicEvent = try? container.decode(RemoteAiMicEvent.self) {
                self = .aiMic(aiMicEvent)
            } else if let musicEvent = try? container.decode(RemoteMusicEvent.self) {
                self = .music(musicEvent)
            } else if let callEvent = try? container.decode(RemoteCallEvent.self) {
                self = .call(callEvent)
            } else if let translationEvent = try? container.decode(RemoteTranslationEvent.self) {
                self = .translation(translationEvent)
            } else {
                self = .unknown
            }
        }
    }
    
    let originatorIdentifier: String
    public let feedbackUUID: UUID?
    public let eventCreationTime: Date
    public let feedbackCategory: FeedbackCategory?
    let eventType: String
    public let eventIdentifier: UUID
    public let eventData: DataEnvelope
}

extension EventContentEnvelope: Identifiable {
    public var id: UUID { eventIdentifier }
}
