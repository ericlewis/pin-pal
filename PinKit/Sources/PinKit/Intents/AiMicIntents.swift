import AppIntents
import Foundation
import PinKit
import SwiftUI
import CollectionConcurrencyKit
import Models

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

extension KeyPath: @unchecked Sendable {}

struct SyncAiMicEventsIntent: AppIntent, SyncIntent {
    
    var currentKeyPath: KeyPath<AppState, Int> = \.numberOfAiMicEventsSynced
    var totalKeyPath: KeyPath<AppState, Int> = \.totalAiMicEventsToSync
    
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
    
    public func perform() async throws -> some IntentResult {
        let chunkSize = 100
        let total = try await service.events(.aiMic, 0, 1).totalElements
        let totalPages = (total + chunkSize - 1) / chunkSize
        
        await MainActor.run {
            withAnimation {
                app.totalAiMicEventsToSync = total
            }
        }
        
        // TODO: do cleanup too
        try await (0..<totalPages).concurrentForEach { page in
            let data = try await service.events(.aiMic, page, chunkSize)
            let result = try await data.content.concurrentMap(process)
                        
            await MainActor.run {
                withAnimation {
                    app.numberOfAiMicEventsSynced += result.count
                }
            }
        }
                        
        try await self.database.save()

        await MainActor.run {
            app.totalAiMicEventsToSync = 0
            app.numberOfAiMicEventsSynced = 0
        }

        return .result()
    }
    
    private func process(_ content: EventContentEnvelope) async throws -> UUID {
        let event = AiMicEvent(from: content)
        await self.database.insert(event)
        return event.uuid
    }
    
    enum Error: Swift.Error {
        case invalidContentType
    }
}

struct SyncCallEventsIntent: AppIntent, SyncIntent {
    
    var currentKeyPath: KeyPath<AppState, Int> = \.numberOfCallEventsSynced
    var totalKeyPath: KeyPath<AppState, Int> = \.totalCallEventsToSync
    
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
    
    public func perform() async throws -> some IntentResult {
        let chunkSize = 100
        let total = try await service.events(.calls, 0, 1).totalElements
        let totalPages = (total + chunkSize - 1) / chunkSize
        
        await MainActor.run {
            withAnimation {
                app.totalCallEventsToSync = total
            }
        }
        
        // TODO: do cleanup too
        try await (0..<totalPages).concurrentForEach { page in
            let data = try await service.events(.calls, page, chunkSize)
            let result = try await data.content.concurrentMap(process)
                        
            await MainActor.run {
                withAnimation {
                    app.numberOfCallEventsSynced += result.count
                }
            }
        }
                        
        try await self.database.save()

        await MainActor.run {
            app.totalCallEventsToSync = 0
            app.numberOfCallEventsSynced = 0
        }

        return .result()
    }
    
    private func process(_ content: EventContentEnvelope) async throws -> UUID {
        let event = PhoneCallEvent(from: content)
        await self.database.insert(event)
        return event.uuid
    }
    
    enum Error: Swift.Error {
        case invalidContentType
    }
}

struct SyncTranslationEventsIntent: AppIntent, SyncIntent {
    
    var currentKeyPath: KeyPath<AppState, Int> = \.numberOfTranslationEventsSynced
    var totalKeyPath: KeyPath<AppState, Int> = \.totalTranslationEventsToSync
    
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
    
    public func perform() async throws -> some IntentResult {
        let chunkSize = 100
        let total = try await service.events(.translation, 0, 1).totalElements
        let totalPages = (total + chunkSize - 1) / chunkSize
        
        await MainActor.run {
            withAnimation {
                app.totalTranslationEventsToSync = total
            }
        }
        
        // TODO: do cleanup too
        try await (0..<totalPages).concurrentForEach { page in
            let data = try await service.events(.translation, page, chunkSize)
            let result = try await data.content.concurrentMap(process)
                        
            await MainActor.run {
                withAnimation {
                    app.numberOfTranslationEventsSynced += result.count
                }
            }
        }
                        
        try await self.database.save()

        await MainActor.run {
            app.totalTranslationEventsToSync = 0
            app.numberOfTranslationEventsSynced = 0
        }

        return .result()
    }
    
    private func process(_ content: EventContentEnvelope) async throws -> UUID {
        let event = TranslationEvent(from: content)
        await self.database.insert(event)
        return event.uuid
    }
    
    enum Error: Swift.Error {
        case invalidContentType
    }
}


struct SyncMusicEventsIntent: AppIntent, SyncIntent {
    
    var currentKeyPath: KeyPath<AppState, Int> = \.numberOfMusicEventsSynced
    var totalKeyPath: KeyPath<AppState, Int> = \.totalMusicEventsToSync
    
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
    
    public func perform() async throws -> some IntentResult {
        let chunkSize = 100
        let total = try await service.events(.music, 0, 1).totalElements
        let totalPages = (total + chunkSize - 1) / chunkSize
        
        await MainActor.run {
            withAnimation {
                app.totalMusicEventsToSync = total
            }
        }
        
        // TODO: do cleanup too
        try await (0..<totalPages).concurrentForEach { page in
            let data = try await service.events(.music, page, chunkSize)
            let result = try await data.content.concurrentMap(process)
                        
            await MainActor.run {
                withAnimation {
                    app.numberOfMusicEventsSynced += result.count
                }
            }
        }
                        
        try await self.database.save()

        await MainActor.run {
            app.totalMusicEventsToSync = 0
            app.numberOfMusicEventsSynced = 0
        }

        return .result()
    }
    
    private func process(_ content: EventContentEnvelope) async throws -> UUID {
        let event = MusicEvent(from: content)
        await self.database.insert(event)
        return event.uuid
    }
    
    enum Error: Swift.Error {
        case invalidContentType
    }
}
