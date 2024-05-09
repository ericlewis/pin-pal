import SwiftData
import Foundation

public typealias PhoneCallEvent = SchemaV1.PhoneCallEvent

extension SchemaV1 {
    
    @Model
    public final class PhoneCallEvent {
        
        @Attribute(.unique)
        public var uuid: UUID
        
        public var duration: Int64?
        public var peers: [PhonePeer]?

        public var feedbackUUID: UUID?
        public var feedbackCategory: FeedbackCategory?
        
        public var createdAt: Date
        
        public init(uuid: UUID, duration: Int64? = nil, peers: [PhonePeer] = [], feedbackUUID: UUID? = nil, feedbackCategory: FeedbackCategory? = nil, createdAt: Date) {
            self.uuid = uuid
            self.duration = duration
            self.peers = peers
            self.feedbackUUID = feedbackUUID
            self.feedbackCategory = feedbackCategory
            self.createdAt = createdAt
        }
        
        public init(from event: EventContentEnvelope) {
            guard case let .call(call) = event.eventData else {
                fatalError()
            }
            self.uuid = event.eventIdentifier
            if let duration = call.duration {
                self.duration = duration.components.attoseconds
            } else {
                self.duration = nil
            }
            self.peers = call.peers.map(PhonePeer.init(from:))
            self.feedbackUUID = event.feedbackUUID
            self.feedbackCategory = event.feedbackCategory
            self.createdAt = event.eventCreationTime
        }
        
        var dur: Duration? {
            guard let duration else {
                return nil
            }
            return .init(secondsComponent: 0, attosecondsComponent: duration)
        }
    }
}

extension PhoneCallEvent {
    public static func all(order: SortOrder = .reverse) -> FetchDescriptor<PhoneCallEvent> {
        FetchDescriptor<PhoneCallEvent>(sortBy: [.init(\.createdAt, order: order)])
    }
}
