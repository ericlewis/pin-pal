import SwiftUI
import SwiftData
import CollectionConcurrencyKit

struct NotesView: View {
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service

    @State
    private var searchQuery = ""
    
    @State
    private var searchResults: [UUID]?
    
    @State
    private var fileImporterPresented = false
    
    @State
    private var isLoading = false
    
    var body: some View {
        @Bindable var navigationStore = navigationStore
        NavigationStack {
            NotesList(uuids: searchResults, order: .reverse, isLoading: isLoading)
                .refreshable {
                    await load()
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu("Create note", systemImage: "plus") {
                            Button("Create", systemImage: "note.text.badge.plus") {
                                self.navigationStore.activeNote = Note.newNote()
                            }
                            Button("Import", systemImage: "square.and.arrow.down") {
                                self.navigationStore.isFileImporterPresented = true
                            }
                        } primaryAction: {
                            self.navigationStore.activeNote = Note.newNote()
                        }
                    }
                }
                .searchable(text: $searchQuery)
                .navigationTitle("Notes")
        }
        .sheet(item: $navigationStore.activeNote) {
            NoteComposerView(editableNote: $0)
        }
        .fileImporter(
            isPresented: $navigationStore.isFileImporterPresented,
            allowedContentTypes: [.plainText],
            onCompletion: handleFileImport(result:)
        )
        .task(id: searchQuery, search)
        .task {
            await load()
        }
    }
    
    private func handleFileImport(result: Result<URL, Error>) {
        Task.detached {
            do {
                switch result {
                case let .success(success):
                    let str = try String(contentsOf: success)
                    self.navigationStore.activeNote = .init(title: success.lastPathComponent, text: str, createdAt: .now)
                case let .failure(failure):
                    break
                }
            } catch {
                print(error)
            }
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
            let res = try await service.search(searchQuery, .notes).memories ?? []
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
            let response = try await service.notes(0, chunkSize)
            await process(content: response.content)
            let responses = try await (1..<response.totalPages).asyncCompactMap { pageNumber in
                try? await service.notes(pageNumber, chunkSize).content
            }
            let responsesContent = responses.flatMap({ $0 })
            var firstResponseContent = response.content
            firstResponseContent.append(contentsOf: responsesContent)
            let fetchedUUIDs = Set(firstResponseContent.compactMap({ $0.get()?.uuid }))
            await process(content: responsesContent)
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
    
    private func process(content: [ContentEnvelope]) async {
        await withThrowingTaskGroup(of: Void.self) { group in
            for item in content {
                let memory = Memory(uuid: item.uuid, favorite: item.favorite, createdAt: item.userCreatedAt)
                if let remoteNote: RemoteNote = item.get() {
                    let note = Note(
                        uuid: remoteNote.uuid,
                        title: remoteNote.title,
                        text: remoteNote.text,
                        createdAt: memory.createdAt
                    )
                    memory.note = note
                }
                group.addTask {
                    await database.insert(memory)
                }
            }
        }
    }
    
    private func pruneStaleRecords(fetchedUUIDs: Set<UUID>) async throws {
        let notes = try await database.fetch(FetchDescriptor<Note>())
        let allUUIDs = Set(notes.compactMap(\.uuid))
        let staleUUIDs = allUUIDs.subtracting(fetchedUUIDs)
        await withTaskGroup(of: Void.self) { group in
            for note in notes {
                if let id = note.uuid, staleUUIDs.contains(id) {
                    group.addTask {
                        await database.delete(note)
                    }
                }
            }
        }
    }
}
