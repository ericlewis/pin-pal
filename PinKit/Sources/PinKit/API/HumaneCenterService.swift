import Foundation
import Models

public enum FeatureFlag: String, Codable {
    case visionAccess
    case betaAccess
}

@Observable public class HumaneCenterService: Sendable {
    public static let shared = HumaneCenterService.live

    public var accessToken: String? {
        (UserDefaults(suiteName: "group.com.ericlewis.Pin-Pal") ?? .standard).string(forKey: Constants.ACCESS_TOKEN)
    }
    
    public var notes: (Int, Int) async throws -> PageableMemoryContentEnvelope
    public var captures: (Int, Int) async throws -> PageableMemoryContentEnvelope
    public var events: (EventDomain, Int, Int) async throws -> PageableEventContentEnvelope
    public var featureFlag: (FeatureFlag) async throws -> FeatureFlagEnvelope
    public var subscription: () async throws -> Subscription
    public var detailedDeviceInformation: () async throws -> DetailedDeviceInfo
    public var create: (NoteEnvelope) async throws -> MemoryContentEnvelope
    public var update: (NoteEnvelope) async throws -> MemoryContentEnvelope
    public var search: (String, SearchDomain) async throws -> SearchResults
    public var deleteEvent: (UUID) async throws -> Void
    public var memory: (UUID) async throws -> MemoryContentEnvelope
    public var toggleFeatureFlag: (FeatureFlag, Bool) async throws -> FeatureFlagEnvelope
    public var lostDeviceStatus: (String) async throws -> LostDeviceEnvelope
    public var toggleLostDeviceStatus: (String, Bool) async throws -> LostDeviceEnvelope
    public var deviceIdentifiers: () async throws -> [String]
    public var deleteAllNotes: () async throws -> Void
    public var bulkFavorite: ([UUID]) async throws -> BulkMemoryActionResult
    public var bulkUnfavorite: ([UUID]) async throws -> BulkMemoryActionResult
    public var bulkRemove: ([UUID]) async throws -> BulkMemoryActionResult

    required public init(
        notes: @escaping (Int, Int) async throws -> PageableMemoryContentEnvelope,
        captures: @escaping (Int, Int) async throws -> PageableMemoryContentEnvelope,
        events: @escaping (EventDomain, Int, Int) async throws -> PageableEventContentEnvelope,
        featureFlag: @escaping (FeatureFlag) async throws -> FeatureFlagEnvelope,
        subscription: @escaping () async throws -> Subscription,
        detailedDeviceInformation: @escaping () async throws -> DetailedDeviceInfo,
        create: @escaping (NoteEnvelope) async throws -> MemoryContentEnvelope,
        update: @escaping (NoteEnvelope) async throws -> MemoryContentEnvelope,
        search: @escaping (String, SearchDomain) async throws -> SearchResults,
        deleteEvent: @escaping (UUID) async throws -> Void,
        memory: @escaping (UUID) async throws -> MemoryContentEnvelope,
        toggleFeatureFlag: @escaping (FeatureFlag, Bool) async throws -> FeatureFlagEnvelope,
        lostDeviceStatus: @escaping (String) async throws -> LostDeviceEnvelope,
        toggleLostDeviceStatus: @escaping (String, Bool) async throws -> LostDeviceEnvelope,
        deviceIdentifiers: @escaping () async throws -> [String],
        deleteAllNotes: @escaping () async throws -> Void,
        bulkFavorite: @escaping ([UUID]) async throws -> BulkMemoryActionResult,
        bulkUnfavorite: @escaping ([UUID]) async throws -> BulkMemoryActionResult,
        bulkRemove: @escaping ([UUID]) async throws -> BulkMemoryActionResult
    ) {
        self.notes = notes
        self.captures = captures
        self.events = events
        self.featureFlag = featureFlag
        self.subscription = subscription
        self.detailedDeviceInformation = detailedDeviceInformation
        self.create = create
        self.update = update
        self.search = search
        self.deleteEvent = deleteEvent
        self.memory = memory
        self.toggleFeatureFlag = toggleFeatureFlag
        self.lostDeviceStatus = lostDeviceStatus
        self.toggleLostDeviceStatus = toggleLostDeviceStatus
        self.deviceIdentifiers = deviceIdentifiers
        self.deleteAllNotes = deleteAllNotes
        self.bulkFavorite = bulkFavorite
        self.bulkUnfavorite = bulkUnfavorite
        self.bulkRemove = bulkRemove
    }
    
    public func isLoggedIn() -> Bool {
        self.accessToken != nil // TODO: also check cookies
    }
}

func extractValue(from text: String, forKey key: String) -> String? {
    let pattern = #"\\"\#(key)\\"[:]\\"([^"]+)\\""#
    
    let regex = try? NSRegularExpression(pattern: pattern, options: [])
    let nsRange = NSRange(text.startIndex..<text.endIndex, in: text)
    
    if let match = regex?.firstMatch(in: text, options: [], range: nsRange) {
        if let valueRange = Range(match.range(at: 1), in: text) {
            return String(text[valueRange])
        }
    }
    
    return nil
}
