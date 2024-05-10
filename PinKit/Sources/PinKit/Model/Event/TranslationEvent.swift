import SwiftData
import Foundation
import Models

public typealias TranslationEvent = SchemaV1.TranslationEvent

extension TranslationEvent: EventDecodable {}
extension TranslationEvent: DeletableEvent {}

extension SchemaV1 {
    
    @Model
    public final class TranslationEvent {
        
        @Attribute(.unique)
        public var uuid: UUID

        public var targetLanguage: String
        public var originLanguage: String
        
        public var feedbackUUID: UUID?
        public var feedbackCategory: FeedbackCategory?
        
        public var createdAt: Date
        
        public init(uuid: UUID, targetLanguage: String, originLanguage: String, feedbackUUID: UUID? = nil, feedbackCategory: FeedbackCategory? = nil, createdAt: Date) {
            self.uuid = uuid
            self.targetLanguage = targetLanguage
            self.originLanguage = originLanguage
            self.feedbackUUID = feedbackUUID
            self.feedbackCategory = feedbackCategory
            self.createdAt = createdAt
        }
        
        public init(from event: EventContentEnvelope) {
            guard case let .translation(translation) = event.eventData else {
                fatalError()
            }
            self.uuid = event.eventIdentifier
            self.originLanguage = translation.originLanguage
            self.targetLanguage = translation.targetLanguage
            self.feedbackUUID = event.feedbackUUID
            self.feedbackCategory = event.feedbackCategory
            self.createdAt = event.eventCreationTime
        }
    }

}

extension TranslationEvent {
    public static func all(order: SortOrder = .reverse) -> FetchDescriptor<TranslationEvent> {
        FetchDescriptor<TranslationEvent>(sortBy: [.init(\.createdAt, order: order)])
    }
}
