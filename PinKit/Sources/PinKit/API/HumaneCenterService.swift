import Foundation

public enum APIError: Error {
    case notAuthorized
    case notFound
}

public enum FeatureFlag: String, Codable {
    case visionAccess
    case betaAccess
}

@Observable public class HumaneCenterService: Sendable {
    public static let shared = HumaneCenterService.live
    
    internal static let rootUrl = URL(string: "https://webapi.prod.humane.cloud/")!
    internal static let captureUrl = rootUrl.appending(path: "capture")
    internal static let memoryUrl = rootUrl.appending(path: "capture").appending(path: "memory")
    internal static let noteUrl = rootUrl.appending(path: "capture").appending(path: "note")
    internal static let aiBusUrl = rootUrl.appending(path: "ai-bus")
    internal static let deviceAssignmentUrl = rootUrl.appending(path: "device-assignments")
    internal static let eventsUrl = rootUrl.appending(path: "notable-events")
    internal static let subscriptionUrl = rootUrl.appending(path: "subscription")
    internal static let subscriptionV3Url = subscriptionUrl.appending(path: "v3/subscription")
    internal static let featureFlagsUrl = rootUrl.appending(path: "feature-flags/v0/feature-flag/flags")
    
    static let sessionUrl = URL(string: "https://humane.center/api/auth/session")!
    
    private let decoder: JSONDecoder
    private let encoder = JSONEncoder()
    private let userDefaults: UserDefaults
    private let sessionTimeout: TimeInterval = 60 * 5 // 5 min
    
    public var accessToken: String? {
        (UserDefaults(suiteName: "group.com.ericlewis.Pin-Pal") ?? .standard).string(forKey: Constants.ACCESS_TOKEN)
    }
    
    private var lastSessionUpdate: Date?
    
    @ObservationIgnored
    public var session: () async throws -> Session
    
    @ObservationIgnored
    public var notes: (Int, Int) async throws -> PageableMemoryContentEnvelope
    
    @ObservationIgnored
    public var captures: (Int, Int) async throws -> PageableMemoryContentEnvelope
    
    @ObservationIgnored
    public var events: (EventDomain, Int, Int) async throws -> PageableEventContentEnvelope
    
    public var allEvents: (Int, Int) async throws -> EventStream
    public var featureFlag: (FeatureFlag) async throws -> FeatureFlagEnvelope
    public var subscription: () async throws -> Subscription
    public var detailedDeviceInformation: () async throws -> DetailedDeviceInfo
    public var create: (NoteEnvelope) async throws -> ContentEnvelope
    public var update: (String, NoteEnvelope) async throws -> ContentEnvelope
    public var search: (String, SearchDomain) async throws -> SearchResults
    public var favorite: (ContentEnvelope) async throws -> Void
    public var unfavorite: (ContentEnvelope) async throws -> Void
    public var delete: (ContentEnvelope) async throws -> Void
    public var deleteEvent: (UUID) async throws -> Void
    public var memory: (UUID) async throws -> ContentEnvelope
    public var toggleFeatureFlag: (FeatureFlag, Bool) async throws -> FeatureFlagEnvelope
    public var lostDeviceStatus: (String) async throws -> LostDeviceEnvelope
    public var toggleLostDeviceStatus: (String, Bool) async throws -> LostDeviceEnvelope
    public var deviceIdentifiers: () async throws -> [String]
    public var deleteAllNotes: () async throws -> Void
    public var bulkFavorite: ([UUID]) async throws -> BulkResponse
    public var bulkUnfavorite: ([UUID]) async throws -> BulkResponse
    public var bulkRemove: ([UUID]) async throws -> BulkResponse

    required public init(
        accessToken: String? = nil,
        userDefaults: UserDefaults = .standard,
        session: @escaping () async throws -> Session,
        notes: @escaping (Int, Int) async throws -> PageableMemoryContentEnvelope,
        captures: @escaping (Int, Int) async throws -> PageableMemoryContentEnvelope,
        events: @escaping (EventDomain, Int, Int) async throws -> PageableEventContentEnvelope,
        allEvents: @escaping (Int, Int) async throws -> EventStream,
        featureFlag: @escaping (FeatureFlag) async throws -> FeatureFlagEnvelope,
        subscription: @escaping () async throws -> Subscription,
        detailedDeviceInformation: @escaping () async throws -> DetailedDeviceInfo,
        create: @escaping (NoteEnvelope) async throws -> ContentEnvelope,
        update: @escaping (String, NoteEnvelope) async throws -> ContentEnvelope,
        search: @escaping (String, SearchDomain) async throws -> SearchResults,
        favorite: @escaping (ContentEnvelope) async throws -> Void,
        unfavorite: @escaping (ContentEnvelope) async throws -> Void,
        delete: @escaping (ContentEnvelope) async throws -> Void,
        deleteEvent: @escaping (UUID) async throws -> Void,
        memory: @escaping (UUID) async throws -> ContentEnvelope,
        toggleFeatureFlag: @escaping (FeatureFlag, Bool) async throws -> FeatureFlagEnvelope,
        lostDeviceStatus: @escaping (String) async throws -> LostDeviceEnvelope,
        toggleLostDeviceStatus: @escaping (String, Bool) async throws -> LostDeviceEnvelope,
        deviceIdentifiers: @escaping () async throws -> [String],
        deleteAllNotes: @escaping () async throws -> Void,
        bulkFavorite: @escaping ([UUID]) async throws -> BulkResponse,
        bulkUnfavorite: @escaping ([UUID]) async throws -> BulkResponse,
        bulkRemove: @escaping ([UUID]) async throws -> BulkResponse
    ) {
        self.userDefaults = userDefaults
        let decoder = JSONDecoder()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSX"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        decoder.dateDecodingStrategy = .formatted(dateFormatter)
        self.decoder = decoder
        self.session = session
        self.notes = notes
        self.captures = captures
        self.events = events
        self.allEvents = allEvents
        self.featureFlag = featureFlag
        self.subscription = subscription
        self.detailedDeviceInformation = detailedDeviceInformation
        self.create = create
        self.update = update
        self.search = search
        self.favorite = favorite
        self.unfavorite = unfavorite
        self.delete = delete
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
