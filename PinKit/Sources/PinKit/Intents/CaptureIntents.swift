import AppIntents
import Foundation
import PinKit
import SwiftUI
import Models
import Photos

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

    public init(from content: MemoryContentEnvelope) async {
        let capture: CaptureEnvelope? = content.get()
        self.id = content.id
        self.url = capture?.makeThumbnailURL()
        self.type = capture?.video == nil ? .photo : .video
        self.createdAt = content.userCreatedAt
        self.modifiedAt = content.userLastModified
    }
    
    public init(from capture: Capture) {
        self.id = capture.uuid
        self.url = nil // capture?.makeThumbnailURL()
        self.type = capture.isPhoto ? .photo : .video
        self.createdAt = capture.createdAt
        self.modifiedAt = capture.modifiedAt
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
        try await database.fetch(Capture.all())
            .map(CaptureEntity.init(from:))
    }

    public static var findIntentDescription: IntentDescription? {
        IntentDescription("",
                          categoryName: "Captures",
                          searchKeywords: ["capture", "photo", "ai pin"],
                          resultValueName: "Captures")
    }
    
    @Dependency
    var service: HumaneCenterService
    
    @Dependency
    var database: any Database
    
    public init() {}
    
    public func entities(for ids: [Self.Entity.ID]) async throws -> Self.Result {
        await ids.asyncCompactMap { id in
            try? await CaptureEntity(from: service.memory(id))
        }
    }
    
    public func entities(matching string: String) async throws -> Self.Result {
        try await entities(for: service.search(string, .captures).memories?.map(\.uuid) ?? [])
    }

    public func suggestedEntities() async throws -> [CaptureEntity] {
        try await database.fetch(Capture.all(limit: 30))
            .map(CaptureEntity.init(from:))
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

    public init(capture: CaptureEntity) {
        self.capture = capture
    }
    
    public init(capture: Capture) {
        self.capture = CaptureEntity(from: capture)
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<IntentFile?> {
        let content = try await service.memory(capture.id)
        guard let file = content.get()?.downloadVideo ?? content.get()?.video else {
            return .result(value: nil)
        }
        let data = try await service.download(capture.id, file)
        return .result(value: .init(data: data, filename: "\(file.fileUUID).mp4"))
    }
}

public struct GetUnprocessedVideoIntent: AppIntent {
    public static var title: LocalizedStringResource = "Get Unprocessed Video"
    public static var description: IntentDescription? = .init("Returns the unprocessed video for a given capture, if it has one.",
                                                              categoryName: "Captures",
                                                              resultValueName: "Video"
    )
    public static var parameterSummary: some ParameterSummary {
        Summary("Get unprocessed video from \(\.$capture)")
    }
    
    @Parameter(title: "Capture")
    public var capture: CaptureEntity

    public init(capture: CaptureEntity) {
        self.capture = capture
    }
    
    public init(capture: Capture) {
        self.capture = CaptureEntity(from: capture)
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<IntentFile?> {
        let content = try await service.memory(capture.id)
        guard let file = content.get()?.originalVideo ?? content.get()?.video else {
            return .result(value: nil)
        }
        let data = try await service.download(capture.id, file)
        return .result(value: .init(data: data, filename: "\(file.fileUUID).mp4"))
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

    public init(capture: CaptureEntity) {
        self.capture = capture
    }
    
    public init(capture: Capture) {
        self.capture = CaptureEntity(from: capture)
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    var service: HumaneCenterService

    public func perform() async throws -> some IntentResult & ReturnsValue<IntentFile?> {
        let content = try await service.memory(capture.id)
        guard let file = content.get()?.closeupAsset ?? content.get()?.thumbnail else {
            return .result(value: nil)
        }
        let data = try await service.download(capture.id, file)
        return .result(value: .init(data: data, filename: "\(file.fileUUID).jpg"))
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
            guard let url = $0.downloadUrl(memoryUUID: capture.id) else {
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
            guard let url = $0.downloadUrl(memoryUUID: capture.id) else {
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
    
    public init(action: FavoriteAction, captures: [CaptureEntity]) {
        self.action = action
        self.captures = captures
    }
    
    public init(action: FavoriteAction, captures: [Capture]) {
        self.action = action
        self.captures = captures.map(CaptureEntity.init(from:))
    }

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database
    
    @Dependency
    public var navigation: Navigation

    public func perform() async throws -> some IntentResult {
        let ids = captures.map(\.id)
        if action == .add {
            let _ = try await service.bulkFavorite(ids)
        } else {
            let _ = try await service.bulkUnfavorite(ids)
        }
        await ids.concurrentForEach { id in
            do {
                try await process(service.memory(id))
            } catch {
                print(error)
            }
        }
        try await self.database.save()
        navigation.show(toast: action == .add ? .favorited : .unfavorited)
        return .result()
    }
    
    private func process(_ content: MemoryContentEnvelope) async throws {
        let newCapture = Capture(from: content)
        await self.database.insert(newCapture)
    }
    
    enum Error: Swift.Error {
        case invalidContentType
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

    public init(entities: [CaptureEntity], confirmBeforeDeleting: Bool) {
        self.confirmBeforeDeleting = confirmBeforeDeleting
        self.entities = entities
    }
    
    public init(entities: [Capture], confirmBeforeDeleting: Bool) {
        self.confirmBeforeDeleting = confirmBeforeDeleting
        self.entities = entities.map(CaptureEntity.init(from:))
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
        if confirmBeforeDeleting {
            try await requestConfirmation(result: .result(dialog: "Are you sure you want to delete ^[\(entities.count) capture](inflect: true)?"))
            let _ = try await service.bulkRemove(ids)
        } else {
            let _ = try await service.bulkRemove(ids)
        }
        
        let predicate = #Predicate<Capture> {
            ids.contains($0.uuid)
        }
        try await database.delete(where: predicate)
        try await database.save()
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

struct SyncCapturesIntent: AppIntent, TaskableIntent {
    public static var title: LocalizedStringResource = "Sync Captures"

    public init() {
        self.force = false
    }
    
    public init(force: Bool) {
        self.force = true
    }

    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = false
    
    var force: Bool
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var database: any Database
    
    @Dependency
    public var app: AppState
    
    public func perform() async throws -> some IntentResult {
        if app.isCapturesLoading { return .result() }
        func reset() async {
            await MainActor.run {
                withAnimation {
                    app.isCapturesLoading = false
                    app.numberOfCapturesSynced = 0
                    app.totalCapturesToSync = 0
                }
            }
        }
        
        await MainActor.run {
            app.isCapturesLoading = true
        }
                
        let first = try await service.captures(0, 1)
        
        let desc = Capture.all(limit: 1)
        let items = try await database.fetch(desc)
        let syncedItemsCount = try await database.count(Capture.all())
        let total = first.totalElements
        let itemsToSync = force ? total : total - syncedItemsCount
        
        if itemsToSync < 0 {
            var remainingToDelete = -itemsToSync
            var currentPage = 0
            let chunkSize = 20
            while remainingToDelete > 0 {
                let remoteCaptures = try await service.captures(currentPage, chunkSize)
                let remoteIDs = remoteCaptures.content.map { $0.id }
                                
                let predicate = #Predicate<Capture> {
                    !remoteIDs.contains($0.uuid)
                }
                var desc = Capture.all()
                desc.predicate = predicate
                let localToDeleteCount = try await database.count(desc)
                
                // Delete these local captures
                try await database.delete(where: predicate)
                try await database.save()
                                
                remainingToDelete -= localToDeleteCount
                currentPage += 1
            }
        } else if itemsToSync == 0, items.first?.uuid == first.content.first?.id {
            // TODO: deeper comparison, probably.
            await reset()
            return .result()
        } else {
            let chunkSize = min(20, max(itemsToSync, 20))
            let totalPages = (itemsToSync + chunkSize - 1) / chunkSize

            await MainActor.run {
                withAnimation {
                    app.totalCapturesToSync = total
                }
            }
            
            let ids = try await (0..<totalPages).concurrentMap { page in
                let data = try await service.captures(page, chunkSize)
                let result = try await data.content.concurrentMap(process)
                await MainActor.run {
                    withAnimation {
                        app.numberOfCapturesSynced += result.count
                    }
                }
                return result
            }
            .flatMap({ $0 })
                            
            try await self.database.save()

            let predicate = #Predicate<Capture> {
                !ids.contains($0.uuid)
            }
            try await self.database.delete(where: predicate)
            try await self.database.save()

            await reset()
        }
    
        return .result()
    }
    
    private func process(_ content: MemoryContentEnvelope) async throws -> UUID {
        let newCapture = Capture(from: content)
        await self.database.insert(newCapture)
        return content.id
    }
    
    enum Error: Swift.Error {
        case invalidContentType
    }
}

public struct CopyCaptureToClipboardIntent: AppIntent {
    public static var title: LocalizedStringResource = "Save Capture to Clipboard"
    public static var description: IntentDescription? = .init("Copies a specified Capture to the current Clipboard.", categoryName: "Captures")
    public static var parameterSummary: some ParameterSummary {
        Summary("Copy \(\.$capture) to Clipboard")
    }
    
    @Parameter(title: "Capture")
    public var capture: CaptureEntity
    
    public init(capture: CaptureEntity) {
        self.capture = capture
    }
    
    public init(capture: Capture) {
        self.capture = CaptureEntity(from: capture)
    }

    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var navigation: Navigation

    public func perform() async throws -> some IntentResult {
        
        if capture.type == .photo {
            guard let data = try await GetBestPhotoIntent(capture: capture).perform().value??.data else {
                return .result()
            }
            UIPasteboard.general.image = UIImage(data: data)
        }
        navigation.show(toast: .copiedToClipboard)
        return .result()
    }
    
    enum Error: Swift.Error {
        case invalidContent
    }
}

public struct SaveCaptureToCameraRollIntent: AppIntent {
    public static var title: LocalizedStringResource = "Save Capture to Camera Roll"
    public static var description: IntentDescription? = .init("Saves a specified Capture to the user's Camera Roll.", categoryName: "Captures")
    public static var parameterSummary: some ParameterSummary {
        Summary("Save \(\.$capture) to Camera Roll")
    }
    
    @Parameter(title: "Capture")
    public var capture: CaptureEntity
    
    public init(capture: CaptureEntity) {
        self.capture = capture
    }
    
    public init(capture: Capture) {
        self.capture = CaptureEntity(from: capture)
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var navigation: Navigation

    public func perform() async throws -> some IntentResult {
        navigation.show(toast: .downloadingCapture)
        switch capture.type {
        case .photo:
            let file = try await GetBestPhotoIntent(capture: capture).perform()
            guard let photo = file.value, let name = photo?.filename, let data = photo?.data else {
                navigation.show(toast: .error)
                return .result()
            }
            let targetURL: URL = .temporaryDirectory.appending(path: name)
            try data.write(to: targetURL)
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: targetURL)
                request?.creationDate = Date()
            }
        case .video:
            let videoFile = try await GetVideoIntent(capture: capture).perform()
            guard let video = videoFile.value, let filename = video?.filename, let data = video?.data else {
                navigation.show(toast: .error)
                return .result()
            }
            let targetURL: URL = .temporaryDirectory.appending(path: filename)
            try data.write(to: targetURL)
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: targetURL)
                request?.creationDate = Date()
            }
        }
        navigation.show(toast: .captureSaved)
        return .result()
    }
    
    enum Error: Swift.Error {
        case invalidContent
    }
}

public struct SaveUnprocessedVideoToCameraRollIntent: AppIntent {
    public static var title: LocalizedStringResource = "Save Unprocessed Video to Camera Roll"
    public static var description: IntentDescription? = .init("Saves a specified Capture's unprocessed video to the user's Camera Roll.", categoryName: "Captures")
    public static var parameterSummary: some ParameterSummary {
        Summary("Save unprocessed video for \(\.$capture) to Camera Roll")
    }
    
    @Parameter(title: "Capture")
    public var capture: CaptureEntity
    
    public init(capture: CaptureEntity) {
        self.capture = capture
    }
    
    public init(capture: Capture) {
        self.capture = CaptureEntity(from: capture)
    }
    
    public init() {}
    
    public static var openAppWhenRun: Bool = false
    public static var isDiscoverable: Bool = true
    
    @Dependency
    public var service: HumaneCenterService
    
    @Dependency
    public var navigation: Navigation

    public func perform() async throws -> some IntentResult {
        navigation.show(toast: .downloadingCapture)
        switch capture.type {
        case .photo:
            break
        case .video:
            let videoFile = try await GetUnprocessedVideoIntent(capture: capture).perform()
            guard let video = videoFile.value, let filename = video?.filename, let data = video?.data else {
                navigation.show(toast: .error)
                return .result()
            }
            let targetURL: URL = .temporaryDirectory.appending(path: filename)
            try data.write(to: targetURL)
            try await PHPhotoLibrary.shared().performChanges {
                let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: targetURL)
                request?.creationDate = Date()
            }
        }
        navigation.show(toast: .captureSaved)
        return .result()
    }
    
    enum Error: Swift.Error {
        case invalidContent
    }
}
