import Foundation

public struct MemoriesResponse: Codable {
    let aiSessions: [ContentEnvelope]?
    let photoCollections: [ContentEnvelope]?
    let aiDJEvents: [ContentEnvelope]?
    let photos: [ContentEnvelope]?
    let videos: [ContentEnvelope]?
    let playTrackEvents: [ContentEnvelope]?
    let notes: [ContentEnvelope]?
    let phoneCalls: [ContentEnvelope]?
    let messages: [ContentEnvelope]?
}
