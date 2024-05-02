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
        NavigationStack(path: $navigationStore.capturesNavigationPath) {
            ScrollView {
                CapturesScrollGrid(uuids: searchResults, order: .reverse, isLoading: isLoading)
            }
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
            print(error)
        }
    }
    
    private func load(chunkSize: Int = 10) async {
        isLoading = true
        do {
            let response = try await service.captures(0, chunkSize)
            await process(content: response.content)
            let responses = try await (1..<response.totalPages).asyncCompactMap { pageNumber in
                try? await service.captures(pageNumber, chunkSize).content
            }
            let responsesContent = responses.flatMap({ $0 })
            var firstResponseContent = response.content
            firstResponseContent.append(contentsOf: responsesContent)
            let fetchedUUIDs = Set(firstResponseContent.compactMap({ $0.uuid }))
            await process(content: responsesContent)
            try await pruneStaleRecords(fetchedUUIDs: fetchedUUIDs)
            try await database.save()
        } catch APIError.notAuthorized {
            self.navigationStore.authenticationPresented = true
        } catch {
            print(error)
        }
        isLoading = false
    }
    
    private func process(content: [ContentEnvelope]) async {
        await withThrowingTaskGroup(of: Void.self) { group in
            for item in content {
                group.addTask {
                    guard var captureEnvelope: CaptureEnvelope = item.get() else { return }
                    let thumbnailAsset = Asset(
                        fileUUID: captureEnvelope.thumbnail.fileUUID,
                        text: captureEnvelope.thumbnail.text,
                        accessToken: captureEnvelope.thumbnail.accessToken,
                        key: captureEnvelope.thumbnail.key,
                        url: captureEnvelope.thumbnail.url
                    )
                    await database.insert(thumbnailAsset)
                    let capture = Capture(
                        uuid: item.uuid,
                        isFavorited: item.favorite,
                        createdAt: item.userCreatedAt,
                        thumbnail: thumbnailAsset
                    )
                    await database.insert(capture)
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
