import AppIntents
import Foundation
import PinKit
import SwiftUI

extension Video {
    func videoDownloadUrl(memoryUUID: UUID) -> URL? {
        return URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(memoryUUID)/file/\(fileUUID)/download")?.appending(queryItems: [
            URLQueryItem(name: "token", value: accessToken),
            URLQueryItem(name: "rawData", value: "false")
        ])
    }
}

extension FileAsset {
    func makeImageURL(memoryUUID: UUID) -> URL? {
        URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(memoryUUID)/file/\(fileUUID)/download")?.appending(queryItems: [
            .init(name: "token", value: accessToken),
            .init(name: "rawData", value: "false")
        ])
    }
}

public enum CaptureType: String, AppEnum, Codable {
    case photo = "PHOTO"
    case video = "VIDEO"
    
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = .init(name: "Capture Type")
    public static var caseDisplayRepresentations: [CaptureType: DisplayRepresentation] = [
        .photo: "Photo",
        .video: "Video"
    ]
}

public struct CaptureEntity: Identifiable {
    public let id: UUID
    
    @Property(title: "Media Type")
    public var type: CaptureType

    @Property(title: "Creation Date")
    public var createdAt: Date
    
    @Property(title: "Last Modified Date")
    public var modifiedAt: Date
    
    let url: URL?

    public init(from content: ContentEnvelope) async {
        let capture: CaptureEnvelope? = content.get()
        self.id = content.id
        self.url = capture?.makeThumbnailURL()
        self.type = capture?.video == nil ? .photo : .video
        self.createdAt = content.userCreatedAt
        self.modifiedAt = content.userLastModified
    }
}

extension CaptureEntity: AppEntity {
    public var displayRepresentation: DisplayRepresentation {
        if let url {
            DisplayRepresentation(title: "\(id.uuidString)", image: .init(url: url))
        } else {
            DisplayRepresentation(title: "\(id.uuidString)")
        }
    }
    
    public static var defaultQuery: CaptureEntityQuery = CaptureEntityQuery()
    public static var typeDisplayRepresentation: TypeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource("Captures"),
        // TODO: pluralize correctly
        numericFormat: LocalizedStringResource("\(placeholder: .int) captures")
    )
}

public struct CaptureEntityQuery: EntityQuery, EntityStringQuery, EnumerableEntityQuery {
    
    public func allEntities() async throws -> [CaptureEntity] {
        try await service.captures(0, 1000)
            .content
            .concurrentMap(CaptureEntity.init(from:))
    }

    public static var findIntentDescription: IntentDescription? {
        IntentDescription("",
                          categoryName: "Captures",
                          searchKeywords: ["capture", "photo", "ai pin"],
                          resultValueName: "Captures")
    }
    
    @Dependency
    var service: HumaneCenterService
    
    public init() {}
    
    public func entities(for ids: [Self.Entity.ID]) async throws -> Self.Result {
        await ids.asyncCompactMap { id in
            try? await CaptureEntity(from: service.memory(id))
        }
    }
    
    public func entities(matching string: String) async throws -> Self.Result {
        try await entities(for: service.search(string, .notes).memories?.map(\.uuid) ?? [])
    }

    public func suggestedEntities() async throws -> [CaptureEntity] {
        try await service.captures(0, 30)
            .content
            .concurrentMap(CaptureEntity.init(from:))
    }
}

public struct GetVideoIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Video"
    public static var description: IntentDescription? = .init("Returns the video for a given capture, if it has one.",
                                                              categoryName: "Captures",
                                                              resultValueName: "Video"
    )
    public static var parameterSummary: some ParameterSummary {
        Summary("Get video from \(\.$capture)")
    }
    
    @Parameter(title: "Capture")
    public var capture: CaptureEntity

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<IntentFile?> {
        let content = try await service.memory(capture.id)
        guard let url = content.videoDownloadUrl() else {
            return .result(value: nil)
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(service.accessToken!)", forHTTPHeaderField: "Authorization")
        let (d, _) = try await URLSession.shared.data(for: req)
        return .result(value: .init(data: d, filename: "\(content.get()?.video?.fileUUID ?? .init()).mp4"))
    }
}

public struct GetBestPhotoIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Best Photo"
    public static var description: IntentDescription? = .init("Returns the best photo for a given capture.",
                                                              categoryName: "Captures",
                                                              resultValueName: "Best Photo"
    )
    public static var parameterSummary: some ParameterSummary {
        Summary("Get best photo from \(\.$capture)")
    }
    
    @Parameter(title: "Capture")
    public var capture: CaptureEntity

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<IntentFile?> {
        guard let cap: CaptureEnvelope = try await service.memory(capture.id).get(), let url = cap.thumbnail.makeImageURL(memoryUUID: capture.id) else {
            return .result(value: nil)
        }
        var req = URLRequest(url: url)
        req.setValue("Bearer \(service.accessToken!)", forHTTPHeaderField: "Authorization")
        let (d, _) = try await URLSession.shared.data(for: req)
        return .result(value: .init(data: d, filename: "\(capture.id).png"))
    }
}

public struct GetOriginalPhotosIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Original Photos"
    public static var description: IntentDescription? = .init("Returns the original photos for a given capture.",
                                                              categoryName: "Captures",
                                                              resultValueName: "Original Photos"
    )
    public static var parameterSummary: some ParameterSummary {
        Summary("Get original photos from \(\.$capture)")
    }
    
    @Parameter(title: "Capture")
    public var capture: CaptureEntity

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<[IntentFile]> {
        guard let captureEnv: CaptureEnvelope = try await service.memory(capture.id).get() else {
            return .result(value: [])
        }
        let urlAndIds: [(UUID, URL)]? = captureEnv.originals?.compactMap({
            guard let url = $0.makeImageURL(memoryUUID: capture.id) else {
                return nil
            }
            return ($0.fileUUID, url)
        })
        let result = try await urlAndIds?.concurrentCompactMap { (id, url) in
            var req = URLRequest(url: url)
            req.setValue("Bearer \(service.accessToken!)", forHTTPHeaderField: "Authorization")
            let (d, _) = try await URLSession.shared.data(for: req)
            return IntentFile(data: d, filename: "\(id).png")
        }
        return .result(value: result ?? [])
    }
}

public struct GetProcessedPhotosIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Processed Photos"
    public static var description: IntentDescription? = .init("Returns the processed photos for a given capture.",
                                                              categoryName: "Captures",
                                                              resultValueName: "Processed Photos"
    )
    public static var parameterSummary: some ParameterSummary {
        Summary("Get original photos from \(\.$capture)")
    }
    
    @Parameter(title: "Capture")
    public var capture: CaptureEntity

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<[IntentFile]> {
        guard let captureEnv: CaptureEnvelope = try await service.memory(capture.id).get() else {
            return .result(value: [])
        }
        let urlAndIds: [(UUID, URL)]? = captureEnv.derivatives?.compactMap({
            guard let url = $0.makeImageURL(memoryUUID: capture.id) else {
                return nil
            }
            return ($0.fileUUID, url)
        })
        let result = try await urlAndIds?.concurrentCompactMap { (id, url) in
            var req = URLRequest(url: url)
            req.setValue("Bearer \(service.accessToken!)", forHTTPHeaderField: "Authorization")
            let (d, _) = try await URLSession.shared.data(for: req)
            return IntentFile(data: d, filename: "\(id).png")
        }
        return .result(value: result ?? [])
    }
}

public struct FavoriteCapturesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Favorite Captures"
    public static var description: IntentDescription? = .init("Adds or removes captures from the set of favorited captures.", categoryName: "Captures")
    public static var parameterSummary: some ParameterSummary {
        Summary("\(\.$action) \(\.$captures) to favorites")
    }

    @Parameter(title: "Favorite Action", default: FavoriteAction.add)
    public var action: FavoriteAction
    
    @Parameter(title: "Captures")
    public var captures: [CaptureEntity]

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult {
        let ids = captures.map(\.id)
        if action == .add {
            let _ = try await service.bulkFavorite(ids)
        } else {
            let _ = try await service.bulkUnfavorite(ids)
        }
        return .result()
    }
}

public struct DeleteCapturesIntent: DeleteIntent {
    public static var title: LocalizedStringResource = "Delete Captures"
    public static var description: IntentDescription? = .init("Deletes the specified captures.", categoryName: "Captures")
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
    
    @Parameter(title: "Captures")
    public var entities: [CaptureEntity]

    @Parameter(title: "Confirm Before Deleting", description: "If toggled, you will need to confirm the captures will be deleted", default: true)
    var confirmBeforeDeleting: Bool

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult {
        let ids = entities.map(\.id)
        if confirmBeforeDeleting {
            try await requestConfirmation(result: .result(dialog: "Are you sure you want to delete ^[\(entities.count) capture](inflect: true)?"))
            let _ = try await service.bulkRemove(ids)
        } else {
            let _ = try await service.bulkRemove(ids)
        }
        return .result()
    }
}

public struct ShowCapturesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Show Captures"
    public static var description: IntentDescription? = .init("Get quick access to captures in Pin Pal", categoryName: "Captures")
    
    public init() {}
    
    public static var openAppWhenRun: Bool = true
    public static var isDiscoverable: Bool = true

    @Dependency
    public var navigation: Navigation
    
    public func perform() async throws -> some IntentResult {
        navigation.selectedTab = .captures
        return .result()
    }
}

public struct SearchCapturesIntent: AppIntent {
    public static var title: LocalizedStringResource = "Search Captures"
    public static var description: IntentDescription? = .init("Performs a search for the specified text.", categoryName: "Captures")
    public static var parameterSummary: some ParameterSummary {
        Summary("Search \(\.$query) in Captures")
    }
    
    @Parameter(title: "Text")
    public var query: String
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<[CaptureEntity]> {
        let results = try await service.search(query, .captures)
        guard let ids = results.memories?.map(\.uuid) else {
            return .result(value: [])
        }
        let memories = await ids.concurrentCompactMap { id in
            try? await service.memory(id)
        }
        return await .result(value: memories.concurrentMap(CaptureEntity.init(from:)))
    }
}
