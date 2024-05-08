import Foundation

public struct EventOverview: Decodable {
    public struct Counts: Codable {
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
    
    public init(from decoder: any Decoder) throws {
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
