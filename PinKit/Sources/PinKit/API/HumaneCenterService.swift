import Foundation

public enum APIError: Error {
    case notAuthorized
    case notFound
}

public enum FeatureFlag: String, Codable {
    case visionAccess
    case betaAccess
}

extension HumaneCenterService {
    actor Service {
        private var accessToken: String? {
            didSet {
                userDefaults.setValue(accessToken, forKey: Constants.ACCESS_TOKEN)
            }
        }
        private var lastSessionUpdate: Date?
        private var expiry: Date?
        private let decoder: JSONDecoder
        private let encoder = JSONEncoder()
        private let session: URLSession
        private let userDefaults: UserDefaults
        
        public init(
            userDefaults: UserDefaults = UserDefaults(suiteName: "group.com.ericlewis.Pin-Pal") ?? .standard
        ) {
            self.session = .shared
            self.userDefaults = userDefaults
            let decoder = JSONDecoder()
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSX"
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(secondsFromGMT: 0)
            decoder.dateDecodingStrategy = .formatted(dateFormatter)
            self.decoder = decoder
        }
        
        private func get<D: Decodable>(url: URL) async throws -> D {
            try await refreshIfNeeded()
            return try await decoder.decode(D.self, from: data(for: makeRequest(url: url)))
        }
        
        private func put<D: Decodable>(url: URL, body: (any Encodable)? = nil) async throws -> D {
            try await refreshIfNeeded()
            var request = try makeRequest(url: url)
            request.httpMethod = "PUT"
            if let body {
                request.httpBody = try encoder.encode(body)
                request.setValue("application/json", forHTTPHeaderField: "content-type")
            }
            return try await decoder.decode(D.self, from: data(for: request))
        }
        
        private func post<D: Decodable>(url: URL, body: (any Encodable)? = nil) async throws -> D {
            try await refreshIfNeeded()
            var request = try makeRequest(url: url)
            request.httpMethod = "POST"
            if let body {
                request.httpBody = try encoder.encode(body)
                request.setValue("application/json", forHTTPHeaderField: "content-type")
            }
            return try await decoder.decode(D.self, from: data(for: request))
        }
        
        private func post(url: URL, body: (any Encodable)? = nil) async throws {
            try await refreshIfNeeded()
            var request = try makeRequest(url: url)
            request.httpMethod = "POST"
            if let body {
                request.httpBody = try encoder.encode(body)
                request.setValue("application/json", forHTTPHeaderField: "content-type")
            }
            let _ = try await data(for: request)
        }
        
        private func delete<D: Decodable>(url: URL) async throws -> D {
            try await refreshIfNeeded()
            var req = try makeRequest(url: url)
            req.httpMethod = "DELETE"
            return try await decoder.decode(D.self, from: data(for: req))
        }
        
        private func delete(url: URL) async throws {
            try await refreshIfNeeded()
            var req = try makeRequest(url: url)
            req.httpMethod = "DELETE"
            let _ = try await data(for: req)
        }
        
        private func unauthenticatedRequest<D: Decodable>(url: URL) async throws -> D {
            try await decoder.decode(D.self, from: data(for: makeRequest(url: url, skipsAuth: true)))
        }
        
        private func data(for request: URLRequest) async throws -> Data {
            let (data, response) = try await session.data(for: request)
            guard let response = response as? HTTPURLResponse else {
                throw APIError.notAuthorized
            }
            if response.statusCode == 404 {
                throw APIError.notFound
            }
            // laziness
            guard (200...304).contains(response.statusCode) else {
                throw APIError.notAuthorized
            }
            return data
        }
        
        private func makeRequest(url: URL, skipsAuth: Bool = false) throws -> URLRequest {
            var req = URLRequest(url: url)
            if !skipsAuth {
                guard let accessToken else {
                    throw APIError.notAuthorized
                }
                req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                req.setValue("application/json", forHTTPHeaderField: "Accept")
                req.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
            }
            return req
        }
        
        public func refreshIfNeeded() async throws {
            do {
                let session = try await session()
                self.accessToken = session.accessToken
            } catch is CancellationError {
                // noop
            } catch {
                let err = (error as NSError)
                if err.domain != NSURLErrorDomain, err.code != NSURLErrorCancelled {
                    throw APIError.notAuthorized
                }
            }
        }
        
        func session() async throws -> Session {
            try await unauthenticatedRequest(url: sessionUrl)
        }
        
        public func captures(page: Int = 0, size: Int = 10, sort: String = "userCreatedAt,DESC", onlyContainingFavorited: Bool = false) async throws -> PageableMemoryContentEnvelope {
            try await get(url: captureUrl.appending(path: "captures").appending(queryItems: [
                .init(name: "page", value: String(page)),
                .init(name: "size", value: String(size)),
                .init(name: "sort", value: sort),
                .init(name: "onlyContainingFavorited", value: onlyContainingFavorited ? "true" : "false")
            ]))
        }
        
        public func events(domain: EventDomain, page: Int = 0, size: Int = 10, sort: String = "eventCreationTime,ASC") async throws -> PageableEventContentEnvelope {
            try await get(url: eventsUrl.appending(path: "mydata").appending(queryItems: [
                .init(name: "domain", value: domain.rawValue),
                .init(name: "page", value: String(page)),
                .init(name: "size", value: String(size)),
                .init(name: "sort", value: sort)
            ]))
        }
        
        public func allEvents(page: Int = 0, size: Int = 10, sort: String = "eventCreationTime,ASC") async throws -> EventStream {
            try await get(url: eventsUrl.appending(path: "mydata").appending(queryItems: [
                .init(name: "page", value: String(page)),
                .init(name: "size", value: String(size)),
                .init(name: "sort", value: sort)
            ]))
        }
        
        public func favorite(uuid: UUID) async throws {
            try await post(url: memoryUrl.appending(path: uuid.uuidString).appending(path: "favorite"))
        }
        
        public func unfavorite(uuid: UUID) async throws {
            try await post(url: memoryUrl.appending(path: uuid.uuidString).appending(path: "unfavorite"))
        }
        
        public func favorite(memory: ContentEnvelope) async throws {
            try await favorite(uuid: memory.uuid)
        }
        
        public func unfavorite(memory: ContentEnvelope) async throws {
            try await unfavorite(uuid: memory.uuid)
        }
        
        public func notes(page: Int = 0, size: Int = 10) async throws -> PageableMemoryContentEnvelope {
            try await get(url: captureUrl.appending(path: "notes").appending(queryItems: [
                .init(name: "page", value: String(page)),
                .init(name: "size", value: String(size))
            ]))
        }
        
        public func create(note: Note) async throws -> ContentEnvelope {
            try await post(url: noteUrl.appending(path: "create"), body: note)
        }
        
        public func update(id: String, with note: Note) async throws -> ContentEnvelope {
            try await post(url: noteUrl.appending(path: id), body: note)
        }
        
        public func subscription() async throws -> Subscription {
            try await get(url: subscriptionV3Url)
        }
        
        public func featureFlag(name: String) async throws -> FeatureFlagEnvelope {
            try await get(url: featureFlagsUrl.appending(path: name))
        }
        
        public func retrieveDetailedDeviceInfo() async throws -> DetailedDeviceInfo {
            let d = try await URLSession.shared.data(from: URL(string: "https://humane.center/account/devices")!).0
            let string = String(data: d, encoding: .utf8)!
            
            return DetailedDeviceInfo(
                id: extractValue(from: string, forKey: "deviceID") ?? "UNKNOWN",
                iccid: extractValue(from: string, forKey: "iccid") ?? "UNKNOWN",
                serialNumber: extractValue(from: string, forKey: "deviceSerialNumber") ?? "UNKNOWN",
                sku: extractValue(from: string, forKey: "sku") ?? "UNKNOWN",
                color: extractValue(from: string, forKey: "deviceColor") ?? "UNKNOWN"
            )
        }
        
        public func delete(memoryId: UUID) async throws {
            try await delete(url: memoryUrl.appending(path: memoryId.uuidString))
        }
        
        public func delete(memory: ContentEnvelope) async throws {
            try await delete(memoryId: memory.uuid)
        }
        
        public func delete(event: EventContentEnvelope) async throws -> Bool {
            try await delete(url: eventsUrl.appending(path: "event").appending(path: event.id.uuidString))
        }
        
        public func search(query: String, domain: SearchDomain) async throws -> SearchResults {
            try await get(url: aiBusUrl.appending(path: "search").appending(queryItems: [
                .init(name: "query", value: query),
                .init(name: "domain", value: domain.rawValue)
            ]))
        }
        
        public func memory(uuid: UUID) async throws -> ContentEnvelope {
            try await get(url: memoryUrl.appending(path: uuid.uuidString))
        }
        
        public func toggleFeatureFlag(_ flag: FeatureFlag, isEnabled: Bool) async throws -> FeatureFlagEnvelope {
            var flagResponse = FeatureFlagEnvelope(state: isEnabled ? .enabled : .disabled)
            let _: String = try await put(url: featureFlagsUrl.appending(path: flag.rawValue), body: flagResponse)
            return try await featureFlag(name: flag.rawValue)
        }
        
        func lostDeviceStatus(deviceId: String) async throws -> LostDeviceEnvelope {
            try await get(url: subscriptionUrl.appending(path: "deviceAuthorization").appending(path: "lostDevice").appending(queryItems: [
                .init(name: "deviceId", value: deviceId)
            ]))
        }
        
        func toggleLostDeviceStatus(deviceId: String, isLost: Bool) async throws -> LostDeviceEnvelope {
            return try await post(url: subscriptionUrl.appending(path: "deviceAuthorization").appending(path: "lostDevice"), body: LostDeviceEnvelope(isLost: isLost, deviceId: deviceId))
        }
        
        func deviceIdentifiers() async throws -> [String] {
            try await get(url: deviceAssignmentUrl.appending(path: "devices"))
        }
        
        func deleteAllNotes() async throws -> Bool {
            try await delete(url: noteUrl)
        }
        
        func remove(uuids: [UUID]) async throws -> BulkResponse {
            try await post(url: memoryUrl.appending(path: "bulk-delete"), body: ["memoryUUIDs": uuids])
        }
        
        func favorite(uuids: [UUID]) async throws -> BulkResponse {
            try await post(url: memoryUrl.appending(path: "bulk-favorite"), body: ["memoryUUIDs": uuids])

        }
        
        func unfavorite(uuids: [UUID]) async throws -> BulkResponse {
            try await post(url: memoryUrl.appending(path: "bulk-unfavorite"), body: ["memoryUUIDs": uuids])
        }
    }
    
    public static func live() -> Self {
        let service = Service()
        return Self(
            session: { try await service.session() },
            notes: { try await service.notes(page: $0, size: $1) },
            captures: { try await service.captures(page: $0, size: $1) },
            events: { try await service.events(domain: $0, page: $1, size: $2) },
            allEvents: { try await service.allEvents(page: $0, size: $1) },
            featureFlag: { try await service.featureFlag(name: $0.rawValue) },
            subscription: { try await service.subscription() },
            detailedDeviceInformation: { try await service.retrieveDetailedDeviceInfo() },
            create: { try await service.create(note: $0) },
            update: { try await service.update(id: $0, with: $1) },
            search: { try await service.search(query: $0, domain: $1) },
            favorite: { try await service.favorite(memory: $0) },
            unfavorite: { try await service.unfavorite(memory: $0) },
            delete: { try await service.delete(memory: $0) },
            deleteEvent: { try await service.delete(event: $0) },
            memory: { try await service.memory(uuid: $0) },
            toggleFeatureFlag: { try await service.toggleFeatureFlag($0, isEnabled: $1) },
            lostDeviceStatus: { try await service.lostDeviceStatus(deviceId: $0) },
            toggleLostDeviceStatus: { try await service.toggleLostDeviceStatus(deviceId: $0, isLost: $1) },
            deviceIdentifiers: { try await service.deviceIdentifiers() },
            deleteAllNotes: { try await service.deleteAllNotes() },
            bulkFavorite: { try await service.favorite(uuids: $0) },
            bulkUnfavorite: { try await service.unfavorite(uuids: $0) },
            bulkRemove: { try await service.remove(uuids: $0) }
        )
    }
}

@Observable public class HumaneCenterService: Sendable {
    public static let shared = HumaneCenterService.live
    
    private static let rootUrl = URL(string: "https://webapi.prod.humane.cloud/")!
    private static let captureUrl = rootUrl.appending(path: "capture")
    private static let memoryUrl = rootUrl.appending(path: "capture").appending(path: "memory")
    private static let noteUrl = rootUrl.appending(path: "capture").appending(path: "note")
    private static let aiBusUrl = rootUrl.appending(path: "ai-bus")
    private static let deviceAssignmentUrl = rootUrl.appending(path: "device-assignments")
    private static let eventsUrl = rootUrl.appending(path: "notable-events")
    private static let subscriptionUrl = rootUrl.appending(path: "subscription")
    private static let subscriptionV3Url = rootUrl.appending(path: "subscription/v3/subscription")
    private static let featureFlagsUrl = rootUrl.appending(path: "feature-flags/v0/feature-flag/flags")
    
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
    public var create: (Note) async throws -> ContentEnvelope
    public var update: (String, Note) async throws -> ContentEnvelope
    public var search: (String, SearchDomain) async throws -> SearchResults
    public var favorite: (ContentEnvelope) async throws -> Void
    public var unfavorite: (ContentEnvelope) async throws -> Void
    public var delete: (ContentEnvelope) async throws -> Void
    public var deleteEvent: (EventContentEnvelope) async throws -> Void
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
        create: @escaping (Note) async throws -> ContentEnvelope,
        update: @escaping (String, Note) async throws -> ContentEnvelope,
        search: @escaping (String, SearchDomain) async throws -> SearchResults,
        favorite: @escaping (ContentEnvelope) async throws -> Void,
        unfavorite: @escaping (ContentEnvelope) async throws -> Void,
        delete: @escaping (ContentEnvelope) async throws -> Void,
        deleteEvent: @escaping (EventContentEnvelope) async throws -> Void,
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
