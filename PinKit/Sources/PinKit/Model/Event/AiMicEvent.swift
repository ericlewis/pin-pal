import SwiftData
import Foundation
import Models

public typealias AiMicEvent = SchemaV1.AiMicEvent

extension AiMicEvent: EventDecodable {}

extension SchemaV1 {
    
    @Model
    public final class AiMicEvent {
        
        @Attribute(.unique)
        public var uuid: UUID

        public var request: String
        public var response: String
        
        public var feedbackUUID: UUID?
        public var feedbackCategory: FeedbackCategory?
        
        public var createdAt: Date
        
        public init(uuid: UUID, request: String, response: String, feedbackUUID: UUID? = nil, feedbackCategory: FeedbackCategory? = nil, createdAt: Date) {
            self.uuid = uuid
            self.request = request
            self.response = response
            self.feedbackUUID = feedbackUUID
            self.feedbackCategory = feedbackCategory
            self.createdAt = createdAt
        }
        
        public init(from event: EventContentEnvelope) {
            guard case let .aiMic(micEvent) = event.eventData else {
                fatalError()
            }
            self.uuid = event.eventIdentifier
            self.request = micEvent.request
            self.response = micEvent.response
            self.feedbackUUID = event.feedbackUUID
            self.feedbackCategory = event.feedbackCategory
            self.createdAt = event.eventCreationTime
        }
    }

}

extension AiMicEvent {
    public static func all(order: SortOrder = .reverse) -> FetchDescriptor<AiMicEvent> {
        FetchDescriptor<AiMicEvent>(sortBy: [.init(\.createdAt, order: order)])
    }
}
