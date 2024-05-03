import SwiftUI
import SwiftData

struct CapturesView: View {
    
    @State
    private var isLoading = false
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(\.database)
    private var database
    
    @State
    private var searchResults: [UUID]?
    
    @State
    private var searchQuery = ""
    
    var body: some View {
        @Bindable var navigationStore = navigationStore
        NavigationStack {
            CapturesScrollGrid(uuids: searchResults, order: .reverse, isLoading: isLoading)
                .refreshable {
                    await load()
                }
                .searchable(text: $searchQuery)
                .navigationTitle("Captures", displayMode: .inline)
        }
        .task(id: searchQuery, search)
        .task {
            await load()
        }
    }
    
    private func search() async {
        do {
            try await Task.sleep(for: .milliseconds(300))
            guard !searchQuery.isEmpty else {
                withAnimation {
                    self.searchResults = nil
                }
                return
            }
            let res = try await service.search(searchQuery, .captures).memories ?? []
            withAnimation {
                searchResults = res.map(\.uuid)
            }
        } catch is CancellationError {
            // noop
        } catch {
            let err = error as NSError
            if err.domain != NSURLErrorDomain, err.code != NSURLErrorCancelled {
                print(error)
            }
        }
    }
    
    private func load(chunkSize: Int = 10) async {
        isLoading = true
        do {
            let response = try await service.captures(0, chunkSize)
            try await process(content: response.content)
            let responses = try await (1..<response.totalPages).asyncCompactMap { pageNumber in
                try? await service.captures(pageNumber, chunkSize).content
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
        } catch APIError.notAuthorized {
            self.navigationStore.authenticationPresented = true
        } catch {
            let err = error as NSError
            if err.domain != NSURLErrorDomain, err.code != NSURLErrorCancelled {
                print(error)
            }
        }
        isLoading = false
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
                group.addTask {
                    await database.insert(memory)
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
                    group.addTask {
                        await database.delete(capture)
                    }
                }
            }
        }
    }
}
