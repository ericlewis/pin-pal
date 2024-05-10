import Foundation
import Get
import Models

enum API {
    
    static let rootUrl = URL(string: "https://webapi.prod.humane.cloud/")!
    static let captureUrl = rootUrl.appending(path: "capture")
    static let memoryUrl = rootUrl.appending(path: "capture").appending(path: "memory")
    static let noteUrl = rootUrl.appending(path: "capture").appending(path: "note")
    static let aiBusUrl = rootUrl.appending(path: "ai-bus")
    static let deviceAssignmentUrl = rootUrl.appending(path: "device-assignments")
    static let eventsUrl = rootUrl.appending(path: "notable-events")
    static let subscriptionUrl = rootUrl.appending(path: "subscription")
    static let lostDeviceUrl = subscriptionUrl.appending(path: "deviceAuthorization/lostDevice")
    static let subscriptionV3Url = subscriptionUrl.appending(path: "v3/subscription")
    static let featureFlagsUrl = rootUrl.appending(path: "feature-flags/v0/feature-flag/flags")
    static let sessionUrl = URL(string: "https://humane.center/api/auth/session")!

    static func session() -> Request<Session> {
        .init(url: API.sessionUrl)
    }
    
    static func notes(page: Int = 0, size: Int = 10) -> Request<PageableMemoryContentEnvelope> {
        .init(url: API.captureUrl.appending(path: "notes"), query: [
            ("page", String(page)),
            ("size", String(size)),
        ])
    }
    
    static func captures(
        page: Int = 0,
        size: Int = 10,
        sort: String = "userCreatedAt,DESC",
        onlyContainingFavorited: Bool = false
    ) -> Request<PageableMemoryContentEnvelope> {
        .init(url: API.captureUrl.appending(path: "captures"), query: [
            ("page", String(page)),
            ("size", String(size)),
            ("sort", sort),
            ("onlyContainingFavorited", onlyContainingFavorited ? "true" : "false")
        ])
    }
    
    static func events(
        domain: EventDomain,
        page: Int = 0,
        size: Int = 10,
        sort: String = "eventCreationTime,ASC"
    ) -> Request<PageableEventContentEnvelope> {
        .init(url: API.eventsUrl.appending(path: "mydata"), query: [
            ("domain", domain.rawValue),
            ("page", String(page)),
            ("size", String(size)),
            ("sort", sort)
        ])
    }
    
    static func favorite(memoryUUIDs: [UUID]) -> Request<BulkMemoryActionResult> {
        .init(url: API.memoryUrl.appending(path: "bulk-favorite"), method: .post, body: ["memoryUUIDs": memoryUUIDs])
    }
    
    static func unfavorite(memoryUUIDs: [UUID]) -> Request<BulkMemoryActionResult> {
        .init(url: API.memoryUrl.appending(path: "bulk-unfavorite"), method: .post, body: ["memoryUUIDs": memoryUUIDs])
    }
    
    static func delete(memoryUUIDs: [UUID]) -> Request<BulkMemoryActionResult> {
        .init(url: API.memoryUrl.appending(path: "bulk-delete"), method: .post, body: ["memoryUUIDs": memoryUUIDs])
    }
    
    static func delete(eventUUID: UUID) -> Request<BulkMemoryActionResult> {
        .init(url: eventsUrl.appending(path: "event").appending(path: eventUUID.uuidString), method: .delete)
    }
    
    static func create(note: NoteEnvelope) -> Request<MemoryContentEnvelope> {
        .init(url: API.noteUrl.appending(path: "create"), method: .post, body: note)
    }
    
    static func update(note: NoteEnvelope) -> Request<MemoryContentEnvelope> {
        .init(url: API.noteUrl.appending(path: note.id!.uuidString), method: .post, body: note)
    }
    
    static func subscription() -> Request<Subscription> {
        .init(url: API.subscriptionV3Url)
    }
    
    static func featureFlag(_ flag: FeatureFlag) -> Request<FeatureFlagEnvelope> {
        .init(url: API.featureFlagsUrl.appending(path: flag.rawValue))
    }
    
    static func memory(uuid: UUID) -> Request<MemoryContentEnvelope> {
        .init(url: API.memoryUrl.appending(path: uuid.uuidString))
    }
    
    static func deleteAllNotes() -> Request<Never> {
        .init(url: API.noteUrl, method: .delete)
    }
    
    static func deviceIdentifiers() -> Request<[String]> {
        .init(url: deviceAssignmentUrl.appending(path: "devices"))
    }
    
    static func search(query: String, domain: SearchDomain) -> Request<SearchResults> {
        .init(url: aiBusUrl.appending(path: "search"), query: [
            ("query", query),
            ("domain", domain.rawValue)
        ])
    }
    
    static func lostDeviceStatus(deviceId: String) -> Request<LostDeviceEnvelope> {
        .init(url: API.lostDeviceUrl, query: [
            ("deviceId", deviceId)
        ])
    }
    
    static func toggleLostDeviceStatus(deviceId: String, isLost: Bool) -> Request<LostDeviceEnvelope> {
        .init(url: API.lostDeviceUrl, method: .post, body: LostDeviceEnvelope(isLost: isLost, deviceId: deviceId))
    }
    
    static func allEvents(
        page: Int = 0,
        size: Int = 10,
        sort: String = "eventCreationTime,ASC"
    ) -> Request<EventStream> {
        .init(url: eventsUrl.appending(path: "mydata"), query: [
            ("page", String(page)),
            ("size", String(size)),
            ("sort", sort)
        ])
    }
    
    static func retrieveDetailedDeviceInfo() async throws -> Request<String> {
        .init(url: URL(string: "https://humane.center/account/devices")!)
    }
    
    static func toggleFeatureFlag(_ flag: FeatureFlag, isEnabled: Bool) -> Request<String> {
        .init(
            url: featureFlagsUrl.appending(path: flag.rawValue),
            method: .put,
            body: FeatureFlagEnvelope(state: isEnabled ? .enabled : .disabled)
        )
    }
}
