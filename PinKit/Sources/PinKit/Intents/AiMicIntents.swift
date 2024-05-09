import AppIntents
import Foundation
import PinKit
import SwiftUI
import CollectionConcurrencyKit

public struct AiMicEntity: Identifiable {
    public let id: UUID
    
    @Property(title: "Request")
    public var request: String
    
    @Property(title: "Response")
    public var response: String
    
    @Property(title: "Request Date")
    public var createdAt: Date

    public init(from content: EventContentEnvelope) async {
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
        try await service.events(.aiMic, 0, 500)
            .content
            .concurrentMap(AiMicEntity.init(from:))
    }

    public static var findIntentDescription: IntentDescription? {
        IntentDescription("Note: only 500 queries will be searched currently.",
                          categoryName: "My Data",
                          searchKeywords: ["ai mic", "llm", "ai pin"],
                          resultValueName: "Ai Mic Queries")
    }
    
    @Dependency
    var service: HumaneCenterService
    
    public init() {}
    
    // TODO: create service endpoint
    public func entities(for ids: [Self.Entity.ID]) async throws -> Self.Result {
        await ids.asyncCompactMap { id in
            nil// try? await AiMicEntity(from: service.event(id))
        }
    }
    
    public func entities(matching string: String) async throws -> Self.Result {
        try await entities(for: service.search(string, .notes).memories?.map(\.uuid) ?? [])
    }

    public func suggestedEntities() async throws -> [AiMicEntity] {
        try await service.events(.aiMic, 0, 10)
            .content
            .concurrentMap(AiMicEntity.init(from:))
    }
}
