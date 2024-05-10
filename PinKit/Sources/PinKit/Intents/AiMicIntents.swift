import AppIntents
import Foundation
import PinKit
import SwiftUI
import CollectionConcurrencyKit
import Models
import SwiftData

public protocol DeletableEvent: Sendable, PersistentModel {
    var uuid: UUID { get }
}

public struct AiMicEntity: Identifiable {
    public let id: UUID
    
    @Property(title: "Request")
    public var request: String
    
    @Property(title: "Response")
    public var response: String
    
    @Property(title: "Request Date")
    public var createdAt: Date

    public init(from content: EventContentEnvelope) {
        id = content.eventIdentifier
        createdAt = content.eventCreationTime
        switch content.eventData {
        case let .aiMic(event):
            request = event.request
            response = event.response
        default:
            fatalError()
        }
    }
    
    public init(from event: AiMicEvent) {
        self.id = event.uuid
        self.request = event.request
        self.response = event.response
        self.createdAt = event.createdAt
    }
}

extension AiMicEntity: AppEntity {
    public var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(request)", subtitle: "\(response)")
    }
    
    public static var defaultQuery: AiMicEntityQuery = AiMicEntityQuery()
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("Ai Mic Queries"),
        // TODO: pluralize correctly
        numericFormat: LocalizedStringResource("\(placeholder: .int) queries")
    )
}

public struct AiMicEntityQuery: EntityQuery, EntityStringQuery, EnumerableEntityQuery {
    
    public func allEntities() async throws -> [AiMicEntity] {
        try await database.fetch(AiMicEvent.all()).map(AiMicEntity.init(from:))
    }

    public static var findIntentDescription: IntentDescription? {
        IntentDescription("",
                          categoryName: "My Data",
                          searchKeywords: ["ai mic", "llm", "ai pin"],
                          resultValueName: "Ai Mic Queries")
    }
    
    @Dependency
    var service: HumaneCenterService
    
    @Dependency
    var database: any Database
    
    public init() {}
    
    public func entities(for ids: [Self.Entity.ID]) async throws -> Self.Result {
        await ids.asyncCompactMap { id in
            nil// try? await AiMicEntity(from: service.event(id))
        }
    }
    
    public func entities(matching string: String) async throws -> Self.Result {
        try await entities(for: service.search(string, .notes).memories?.map(\.uuid) ?? [])
    }

    public func suggestedEntities() async throws -> [AiMicEntity] {
        try await database.fetch(AiMicEvent.all()).map(AiMicEntity.init(from:))
    }
}

public struct DeleteAiMicEventsIntent: DeleteIntent {
    public static var title: LocalizedStringResource = "Delete Ai Mic Events"
    public static var description: IntentDescription? = .init("Deletes the specified event.", categoryName: "My Data")
    public static var parameterSummary: some ParameterSummary {
        When(\.$confirmBeforeDeleting, .equalTo, true, {
            Summary("Delete \(\.$entities)") {
                \.$confirmBeforeDeleting
            }
        }, otherwise: {
            Summary("Immediately delete \(\.$entities)") {
                \.$confirmBeforeDeleting
            }
        })
    }
    
    @Parameter(title: "Events")
    public var entities: [AiMicEntity]

    @Parameter(title: "Confirm Before Deleting", description: "If toggled, you will need to confirm the requests will be deleted", default: true)
    var confirmBeforeDeleting: Bool
    
    public init(entities: [AiMicEntity], confirmBeforeDeleting: Bool) {
        self.entities = entities
        self.confirmBeforeDeleting = confirmBeforeDeleting
    }
    
    public init(entities: [AiMicEvent], confirmBeforeDeleting: Bool) {
        self.entities = entities.map(AiMicEntity.init(from:))
        self.confirmBeforeDeleting = confirmBeforeDeleting
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database

    public func perform() async throws -> some IntentResult {
        let ids = entities.map(\.id)
        
        func delete() async throws {
            await ids.concurrentForEach { id in
                try? await service.deleteEvent(id)
            }
            try await database.delete(where: #Predicate<AiMicEvent> { ids.contains($0.uuid) })
            try await database.save()
        }
        
        if confirmBeforeDeleting {
            try await requestConfirmation(result: .result(dialog: "Are you sure you want to delete?"))
            try await delete()
        } else {
            try await delete()
        }
        
        return .result()
    }
}

public struct DeleteEventsIntent: AppIntent {
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = false
    
    public static var title: LocalizedStringResource = "Delete Events"
    public static var description: IntentDescription? = .init("Deletes the specified event.", categoryName: "My Data")
    
    public var entities: [any DeletableEvent]

    public init(entities: [any DeletableEvent]) {
        self.entities = entities
    }
    
    public init() {
        self.entities = []
    }

    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database

    public func perform() async throws -> some IntentResult {        
        for entity in entities {
            try? await service.deleteEvent(entity.uuid)
            await database.delete(entity)
            entity.modelContext?.delete(entity)
        }
        
        try await database.save()
        
        return .result()
    }
}

extension KeyPath: @unchecked Sendable {}

struct SyncAiMicEventsIntent: AppIntent, SyncManager {
    
    typealias Event = AiMicEvent
    
    var currentKeyPath: WritableKeyPath<AppState, Int> = \.numberOfAiMicEventsSynced
    var totalKeyPath: WritableKeyPath<AppState, Int> = \.totalAiMicEventsToSync
    var domain: EventDomain = .aiMic
    
    public static var title: LocalizedStringResource = "Full Sync Ai Mic Requests"

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = false
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database
    
    @Dependency
    public var app: AppState
}

struct SyncCallEventsIntent: AppIntent, SyncManager {
    
    typealias Event = PhoneCallEvent

    var currentKeyPath: WritableKeyPath<AppState, Int> = \.numberOfCallEventsSynced
    var totalKeyPath: WritableKeyPath<AppState, Int> = \.totalCallEventsToSync
    var domain: EventDomain = .calls

    public static var title: LocalizedStringResource = "Full Sync Phone Call Events"

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = false
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database
    
    @Dependency
    public var app: AppState
}

struct SyncTranslationEventsIntent: AppIntent, SyncManager {
    
    typealias Event = TranslationEvent
    
    var currentKeyPath: WritableKeyPath<AppState, Int> = \.numberOfTranslationEventsSynced
    var totalKeyPath: WritableKeyPath<AppState, Int> = \.totalTranslationEventsToSync
    var domain: EventDomain = .translation
    
    public static var title: LocalizedStringResource = "Full Sync Translation Events"

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = false
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database
    
    @Dependency
    public var app: AppState
}


struct SyncMusicEventsIntent: AppIntent, SyncManager {
    
    typealias Event = MusicEvent
    
    var currentKeyPath: WritableKeyPath<AppState, Int> = \.numberOfMusicEventsSynced
    var totalKeyPath: WritableKeyPath<AppState, Int> = \.totalMusicEventsToSync
    var domain: EventDomain = .music

    public static var title: LocalizedStringResource = "Full Sync Music Events"

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = false
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database
    
    @Dependency
    public var app: AppState
}
