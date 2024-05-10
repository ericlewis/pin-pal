import Foundation

public struct RemoteSmartGeneratedPlaylist: Codable {
    static let decoder = JSONDecoder()
    
    public struct Track: Codable {
        public let title: String
        public let artists: [String]
        
        public init(from decoder: any Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.title = try container.decode(String.self, forKey: .title)
            let artistsData = try container.decode(String.self, forKey: .artists)
            self.artists = artistsData.dropFirst().dropLast().split(separator: ", ").map({ String($0) })
        }
        
        enum CodingKeys: CodingKey {
            case title
            case artists
        }
    }
    
    public let tracks: [Track]
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        guard let tracksData = try container.decode(String.self, forKey: .tracks).data(using: .utf8) else {
            self.tracks = []
            return
        }
        self.tracks = try Self.decoder.decode([Track].self, from: tracksData)
    }
}

public struct RemoteMusicEvent: Codable {
    public let artistName: String?
    public let albumName: String?
    public let trackTitle: String?
    public let prompt: String?
    public let albumArtUuid: UUID?
    public let length: String? // number of tracks
    public let generatedPlaylist: RemoteSmartGeneratedPlaylist?
    public let sourceService: String
    public let trackID: String?
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.artistName = try container.decodeIfPresent(String.self, forKey: .artistName)
        self.albumName = try container.decodeIfPresent(String.self, forKey: .albumName)
        self.trackTitle = try container.decodeIfPresent(String.self, forKey: .trackTitle)
        self.prompt = try container.decodeIfPresent(String.self, forKey: .prompt)
        self.albumArtUuid = try container.decodeIfPresent(UUID.self, forKey: .albumArtUuid)
        self.length = try container.decodeIfPresent(String.self, forKey: .length)
        self.sourceService = try container.decode(String.self, forKey: .sourceService)
        self.trackID = try container.decodeIfPresent(String.self, forKey: .trackID)
        guard let playlistData = try container.decodeIfPresent(String.self, forKey: .generatedPlaylist)?.data(using: .utf8) else {
            self.generatedPlaylist = nil
            return
        }
        self.generatedPlaylist = try JSONDecoder().decode(RemoteSmartGeneratedPlaylist.self, from: playlistData)
    }
}

