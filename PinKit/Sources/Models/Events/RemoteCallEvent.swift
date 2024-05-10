import Foundation

public struct RemoteCallEvent: Codable {
    public struct Peer: Codable {
        public let displayName: String
        public let phoneNumber: String
    }
    
    public let duration: Duration?
    public let peers: [Peer]
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.peers = try container.decode([Peer].self, forKey: .peers)
        if let durationSeconds = try container.decodeIfPresent(Double.self, forKey: .durationSeconds) {
            self.duration = .seconds(durationSeconds)
        } else {
            self.duration = nil
        }
    }
    
    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(self.duration, forKey: .durationSeconds)
        try container.encode(self.peers, forKey: .peers)
    }
    
    enum CodingKeys: CodingKey {
        case durationSeconds
        case peers
    }
}
