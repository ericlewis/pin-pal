import SwiftUI
import SwiftData

struct Notes: View {
    
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
                                self.navigationStore.activeNote = _Note.newNote()
                            }
                            Button("Import", systemImage: "square.and.arrow.down") {
                                self.fileImporterPresented = true
                            }
                        } primaryAction: {
                            self.navigationStore.activeNote = _Note.newNote()
                        }
                    }
                }
                .searchable(text: $searchQuery)
                .navigationTitle("Notes")
        }
        .sheet(item: $navigationStore.activeNote) {
            Composer(editableNote: $0)
        }
        .fileImporter(
            isPresented: $fileImporterPresented,
            allowedContentTypes: [.plainText]
        ) { result in
            Task.detached {
                do {
                    switch result {
                    case let .success(success):
                        let str = try String(contentsOf: success)
                        self.navigationStore.activeNote = .init(title: success.lastPathComponent, text: str)
                    case let .failure(failure):
                        break
                    }
                } catch {
                    print(error)
                }
            }
        }
        .task(id: searchQuery) {
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
                print(error)
            }
        }
        .task {
            await load()
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
            print(error)
        }
        isLoading = false
    }
    
    private func process(content: [ContentEnvelope]) async {
        await withThrowingTaskGroup(of: Void.self) { group in
            for item in content {
                group.addTask {
                    guard var note: Note = item.get() else { return }
                    note.memoryId = item.uuid
                    await database.insert(_Note(from: note, isFavorited: item.favorite, createdAt: item.userCreatedAt))
                }
            }
        }
    }
    
    private func pruneStaleRecords(fetchedUUIDs: Set<UUID>) async throws {
        let notes = try await database.fetch(FetchDescriptor<_Note>())
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

struct NotesList: View {
    
    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(\.isSearching)
    private var isSearching
    
    @AccentColor
    private var tint
    
    @Query
    private var notes: [_Note]
    
    let isLoading: Bool
    
    init(uuids: [UUID?]?, order: SortOrder, isLoading: Bool) {
        var descriptor = FetchDescriptor(sortBy: [SortDescriptor(\_Note.createdAt, order: order)])
        if let uuids {
            descriptor.predicate = #Predicate<_Note> {  uuids.contains($0.memoryUuid) }
        }
        self._notes = .init(descriptor)
        self.isLoading = isLoading
    }
    
    var body: some View {
        List {
            ForEach(notes) { note in
                Button {
                    navigationStore.activeNote = note
                } label: {
                    LabeledContent {} label: {
                        Text(note.title)
                            .foregroundStyle(tint)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .overlay(alignment: .topTrailing) {
                                if note.isFavorited {
                                    Image(systemName: "heart")
                                        .symbolVariant(.fill)
                                        .foregroundStyle(.red)
                                }
                            }
                        Text(LocalizedStringKey(note.text))
                            .lineLimit(note.text.count > 500 ? 5 : nil)
                            .foregroundStyle(.primary)
                        Text(note.createdAt, format: .dateTime)
                            .foregroundStyle(.tertiary)
                    }
                    .tint(.primary)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    FavoriteButton(for: note)
                        .tint(.pink)
                }
            }
            .onDelete(perform: deleteNotes)
        }
        .overlay {
            if isLoading, notes.isEmpty {
                ProgressView()
            } else if isSearching, !isLoading, notes.isEmpty {
                ContentUnavailableView.search
            } else if notes.isEmpty {
                ContentUnavailableView("No notes yet", systemImage: "note.text")
            }
        }
    }
    
    private func deleteNotes(at indexSet: IndexSet) {
        Task {
            do {
                for index in indexSet {
                    let note = notes[index]
                    try await database.delete(note)
                    if let memoryUuid = note.memoryUuid {
                        try await service.deleteByNoteId(memoryUuid)
                    }
                }
                try await database.save()
            } catch {
                print("Error deleting note: \(error)")
            }
        }
    }
}
