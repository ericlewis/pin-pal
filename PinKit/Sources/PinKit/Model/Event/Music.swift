import SwiftData
import Foundation

public typealias MusicEvent = SchemaV1.MusicEvent

extension SchemaV1 {
    
    @Model
    public final class MusicEvent {
        
        @Attribute(.unique)
        public var uuid: UUID

        public var artistName: String?
        public var albumName: String?
        public var trackTitle: String?
        public var albumArtUUID: UUID?
        
        // TODO: playlist
        public var prompt: String?
        public var trackCount: Int?
        
        public var sourceService: String?
        public var sourceTrackId: String?

        public var feedbackUUID: UUID?
        public var feedbackCategory: FeedbackCategory?
        
        public var createdAt: Date
        
        public init(
            uuid: UUID,
            artistName: String? = nil,
            albumName: String? = nil,
            trackTitle: String? = nil,
            albumArtUUID: UUID? = nil,
            prompt: String? = nil,
            trackCount: Int? = nil,
            sourceService: String? = nil,
            sourceTrackId: String? = nil,
            feedbackUUID: UUID? = nil,
            feedbackCategory: FeedbackCategory? = nil,
            createdAt: Date
        ) {
            self.uuid = uuid
            self.artistName = artistName
            self.albumName = albumName
            self.trackTitle = trackTitle
            self.albumArtUUID = albumArtUUID
            self.prompt = prompt
            self.trackCount = trackCount
            self.sourceService = sourceService
            self.sourceTrackId = sourceTrackId
            self.feedbackUUID = feedbackUUID
            self.feedbackCategory = feedbackCategory
            self.createdAt = createdAt
        }
        
        public init(from event: EventContentEnvelope) {
            self.uuid = event.eventIdentifier
            self.feedbackUUID = event.feedbackUUID
            self.feedbackCategory = event.feedbackCategory
            self.createdAt = event.eventCreationTime
            
            guard case let .music(music) = event.eventData else {
                fatalError()
            }
            
            self.artistName = music.artistName
            self.albumName = music.albumName
            self.trackTitle = music.trackTitle
            self.albumArtUUID = music.albumArtUuid
            self.prompt = music.prompt
            self.sourceService = music.sourceService
            self.sourceTrackId = music.trackID
            
            if let len = music.length {
                self.trackCount = Int(len)
            }
        }
    }

}

extension MusicEvent {
    public static func all(order: SortOrder = .reverse) -> FetchDescriptor<MusicEvent> {
        FetchDescriptor<MusicEvent>(sortBy: [.init(\.createdAt, order: order)])
    }
}
