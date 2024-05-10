import Foundation

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
        
        public func create(note: NoteEnvelope) async throws -> ContentEnvelope {
            try await post(url: noteUrl.appending(path: "create"), body: note)
        }
        
        public func update(id: String, with note: NoteEnvelope) async throws -> ContentEnvelope {
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
        
        public func delete(eventUUID: UUID) async throws -> Bool {
            try await delete(url: eventsUrl.appending(path: "event").appending(path: eventUUID.uuidString))
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
            deleteEvent: { try await service.delete(eventUUID: $0) },
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
