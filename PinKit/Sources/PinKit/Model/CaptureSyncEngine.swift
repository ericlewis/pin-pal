import SwiftData
import Foundation

@Observable public final class CaptureSyncEngine {
    
    let service: HumaneCenterService
    let database: any Database
    let navigationStore: NavigationStore
    
    var previousCount = 0
    var lastMemoryId: UUID = .init()
    
    public init(service: HumaneCenterService, database: any Database, navigationStore: NavigationStore) {
        self.service = service
        self.database = database
        self.navigationStore = navigationStore
    }
    
    public func sync() async {
        await load {
            try await service.captures($0, $1)
        }
    }
    
    private func load(task: (Int, Int) async throws -> PageableMemoryContentEnvelope, chunkSize: Int = 10) async {
        do {
            let response = try await task(0, chunkSize)
            guard previousCount != response.totalElements, lastMemoryId != response.content.first?.uuid else { throw CancellationError() }
            try await process(content: response.content)
            let responses = try await (1..<response.totalPages).asyncCompactMap { pageNumber in
                try? await task(pageNumber, chunkSize).content
            }
            let responsesContent = responses.flatMap({ $0 })
            var firstResponseContent = response.content
            firstResponseContent.append(contentsOf: responsesContent)
            let fetchedRecords: [CaptureEnvelope] = firstResponseContent.compactMap({ $0.get() })
            let fetchedUUIDs = Set(fetchedRecords.map(\.uuid))
            try Task.checkCancellation()
            try await process(content: responsesContent)
            try await pruneStaleRecords(fetchedUUIDs: fetchedUUIDs)
            try await database.save()
            previousCount = response.totalElements
            lastMemoryId = response.content.first?.uuid ?? .init()
        } catch is CancellationError {
            // noop
        } catch APIError.notAuthorized {
            self.navigationStore.authenticationPresented = true
        } catch {
            let err = error as NSError
            if err.domain != NSURLErrorDomain, err.code != NSURLErrorCancelled {
                print(error)
            }
        }
    }
    
    private func process(content: [ContentEnvelope]) async throws {
        try await withThrowingTaskGroup(of: Void.self) { group in
            for item in content {
                let memory = Memory(uuid: item.uuid, favorite: item.favorite, createdAt: item.userCreatedAt)
                if let remoteCapture: CaptureEnvelope = item.get() {
                    let capture = Capture(
                        uuid: remoteCapture.uuid,
                        type: remoteCapture.type,
                        createdAt: memory.createdAt,
                        originals: [],
                        derivatives: []
                    )
                    
                    let captureThumbnail = remoteCapture.thumbnail
                    let thumbnail = Asset(fileUUID: captureThumbnail.fileUUID, accessToken: captureThumbnail.accessToken)
                    capture.thumbnail = thumbnail
                    
                    if let captureVideo = remoteCapture.video {
                        let video = Asset(fileUUID: captureVideo.fileUUID, accessToken: captureVideo.accessToken)
                        capture.video = video
                    }
                    
                    memory.capture = capture
                }
                group.addTask { [weak self] in
                    await self?.database.insert(memory)
                }
            }
        }
    }
    
    private func pruneStaleRecords(fetchedUUIDs: Set<UUID>) async throws {
        let captures = try await database.fetch(FetchDescriptor<Capture>())
        let allUUIDs = Set(captures.map(\.uuid))
        let staleUUIDs = allUUIDs.subtracting(fetchedUUIDs)
        await withTaskGroup(of: Void.self) { group in
            for capture in captures {
                if staleUUIDs.contains(capture.uuid) {
                    group.addTask { [weak self] in
                        await self?.database.delete(capture)
                    }
                }
            }
        }
    }
}
