import Foundation

public enum APIError: Error {
    case notAuthorized
}

@Observable public class API {
    public static let shared = API()
    
    private static let rootUrl = URL(string: "https://webapi.prod.humane.cloud/")!
    private static let captureUrl = rootUrl.appending(path: "capture")
    private static let memoryUrl = rootUrl.appending(path: "capture").appending(path: "memory")
    private static let noteUrl = rootUrl.appending(path: "capture").appending(path: "note")
    private static let aiBusUrl = rootUrl.appending(path: "ai-bus")
    private static let deviceAssignmentUrl = rootUrl.appending(path: "device-assignments")
    private static let eventsUrl = rootUrl.appending(path: "notable-events")
    private static let subscriptionUrl = rootUrl.appending(path: "subscription")
    private static let subscriptionV3Url = rootUrl.appending(path: "subscription/v3/subscription")
    private static let addonsUrl = rootUrl.appending(path: "subscription/addons")
    private static let featureFlagsUrl = rootUrl.appending(path: "feature-flags/v0/feature-flag/flags")

    private let sessionUrl = URL(string: "https://humane.center/api/auth/session")!
    
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder = JSONEncoder()
    private let userDefaults: UserDefaults
    private let sessionTimeout: TimeInterval = 60 * 5 // 5 min
    
    private var accessToken: String?
    private var lastSessionUpdate: Date?
    
    public init(accessToken: String? = nil, userDefaults: UserDefaults = .standard) {
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
    
    private func unauthenticatedRequest<D: Decodable>(url: URL) async throws -> D {
        try await decoder.decode(D.self, from: data(for: makeRequest(url: url, skipsAuth: true)))
    }
    
    private func data(for request: URLRequest) async throws -> Data {
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse, (200...304).contains(response.statusCode) else {
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
    
    public func isLoggedIn() -> Bool {
        self.accessToken != nil // TODO: also check cookies
    }
    
    public func refreshIfNeeded() async throws {
        let accessToken = try await session().accessToken
        self.accessToken = accessToken
        self.lastSessionUpdate = .now
    }
}

extension API {
    func session() async throws -> Session {
        try await unauthenticatedRequest(url: sessionUrl)
    }
    
    public func captures(page: Int = 0, size: Int = 10, sort: String = "userCreatedAt,DESC", onlyContainingFavorited: Bool = false) async throws -> CapturesResponseContainer {
        try await get(url: Self.captureUrl.appending(path: "captures").appending(queryItems: [
            .init(name: "page", value: String(page)),
            .init(name: "size", value: String(size)),
            .init(name: "sort", value: sort),
            .init(name: "onlyContainingFavorited", value: onlyContainingFavorited ? "true" : "false")
        ]))
    }
    
    func capturesList(for uuids: [UUID]) async throws -> Bool {
        try await get(url: Self.captureUrl.appending(path: "captures").appending(path: "list").appending(queryItems: [
            .init(name: "uuid", value: uuids.map(\.uuidString).joined(separator: ","))
        ]))
    }
    
    func memory(id: String) async throws -> Bool {
        try await get(url: Self.memoryUrl.appending(path: id, directoryHint: .notDirectory))
    }
    
    public func delete(memory: Memory) async throws -> String {
        try await delete(url: Self.memoryUrl.appending(path: memory.uuid.uuidString))
    }
    
    func delete(memoryId: UUID) async throws -> String {
        try await delete(url: Self.memoryUrl.appending(path: memoryId.uuidString))
    }
    
    func search(query: String, page: Int = 0, size: Int = 10, sort: String = "createdAt,DESC") async throws -> Bool {
        try await get(url: Self.captureUrl.appending(path: "search").appending(queryItems: [
            .init(name: "query", value: query),
            .init(name: "page", value: String(page)),
            .init(name: "size", value: String(size)),
            .init(name: "sort", value: sort)
        ]))
    }
    
    func search(query: String, domain: Domain) async throws -> String {
        try await get(url: Self.aiBusUrl.appending(path: "search").appending(queryItems: [
            .init(name: "query", value: query),
            .init(name: "domain", value: domain.rawValue)
        ]))
    }
    
    func deviceIdentifiers() async throws -> [String] {
        try await get(url: Self.deviceAssignmentUrl.appending(path: "devices"))
    }

    public func events(domain: Domain = .captures, page: Int = 0, size: Int = 10, sort: String = "eventCreationTime,ASC") async throws -> ResponseContainer {
        try await get(url: Self.eventsUrl.appending(path: "mydata").appending(queryItems: [
            .init(name: "domain", value: domain.rawValue),
            .init(name: "page", value: String(page)),
            .init(name: "size", value: String(size)),
            .init(name: "sort", value: sort)
        ]))
    }
    
    // TODO: result is wrong
    func delete(event id: String) async throws -> Bool {
        try await delete(url: Self.eventsUrl.appending(path: "event").appending(path: id, directoryHint: .notDirectory))
    }

    func eventsOverview() async throws -> EventOverview {
        try await get(url: Self.eventsUrl.appending(path: "mydata").appending(path: "overview"))
    }
    
    func memoryDerivatives(for id: String) async throws -> ResponseContainer {
        try await get(url: Self.memoryUrl.appending(path: id).appending(path: "derivatives"))
    }
    
    func memoryOriginals(for id: String) async throws -> ResponseContainer {
        try await get(url: Self.memoryUrl.appending(path: id).appending(path: "originals"))
    }
        
    func index(memory id: String) async throws -> ResponseContainer {
        try await post(url: Self.memoryUrl.appending(path: id).appending(path: "index"))
    }
    
    func tag(memory id: String) async throws -> ResponseContainer {
        try await post(url: Self.memoryUrl.appending(path: id).appending(path: "tag"))
    }
    
    func remove(tag id: String, from memory: String) async throws -> ResponseContainer {
        try await delete(url: Self.memoryUrl.appending(path: id).appending(path: "tag"))
    }
    
    // TODO: wtf does this even mean
    func save(search: String) async throws -> Bool {
        try await get(url: Self.captureUrl.appending(path: "search").appending(path: "save"))
    }
        
    func memories() async throws -> MemoriesResponse {
        try await get(url: Self.captureUrl.appending(path: "memories"))
    }
    
    public func favorite(memory: Memory) async throws {
        try await post(url: Self.memoryUrl.appending(path: memory.uuid.uuidString).appending(path: "favorite"))
    }
    
    public func unfavorite(memory: Memory) async throws {
        try await post(url: Self.memoryUrl.appending(path: memory.uuid.uuidString).appending(path: "unfavorite"))
    }
    
    public func notes() async throws -> NotesResponseContainer {
        try await get(url: Self.captureUrl.appending(path: "notes"))
    }
    
    public func create(note: Note) async throws -> Memory {
        try await post(url: Self.noteUrl.appending(path: "create"), body: note)
    }
    
    public func update(id: String, with note: Note) async throws -> Memory {
        try await post(url: Self.noteUrl.appending(path: id), body: note)
    }
    
    func deleteAllNotes() async throws -> Bool {
        try await delete(url: Self.noteUrl)
    }
    
    public func subscription() async throws -> Subscription {
        try await get(url: Self.subscriptionV3Url)
    }
        
    // TODO: use correct method
    func pauseSubscription() async throws -> Bool {
        try await get(url: Self.subscriptionV3Url)
    }
    
    // TODO: use correct method
    func unpauseSubscription() async throws -> Bool {
        try await get(url: Self.subscriptionV3Url)
    }
    
    // has a postable version
    func addons() async throws -> [Addon] {
        try await get(url: Self.addonsUrl)
    }
    
    func delete(addon: Addon) async throws -> Bool {
        try await delete(url: Self.addonsUrl.appending(path: addon.spid))
    }
    
    func availableAddons() async throws -> [Addon] {
        try await get(url: Self.addonsUrl.appending(path: "types"))
    }
    
    func lostStatus(deviceId: String) async throws -> LostDeviceResponse {
        try await get(url: Self.subscriptionUrl.appending(path: "deviceAuthorization").appending(path: "lostDevice").appending(queryItems: [
            .init(name: "deviceId", value: deviceId)
        ]))
    }
    
    public func featureFlag(name: String) async throws -> FeatureFlagResponse {
        try await get(url: Self.featureFlagsUrl.appending(path: name))
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
