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
    private var noteToEdit: _Note?
    
    @State
    private var searchQuery = ""

    @State
    private var searchResults: [UUID]?

    var body: some View {
        NavigationStack {
            NotesList(noteToEdit: $noteToEdit, uuids: searchResults, order: .reverse)
                .refreshable {
                    await load()
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button("Create note", systemImage: "plus") {
                            noteToEdit = _Note(from: .create(), isFavorited: false, createdAt: .now)
                        }
                    }
                }
                .searchable(text: $searchQuery)
                .navigationTitle("Notes")
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
                guard let res = try await service.search(searchQuery, .notes).memories else {
                    return
                }
                withAnimation {
                    searchResults = res.map(\.uuid)
                }
            } catch is CancellationError {
                // noop
            } catch {
                print("boobh", error)
            }
        }
        .task {
            await load()
        }
        .sheet(item: $noteToEdit) { Composer(editableNote: $0) }
    }

    private func load(chunkSize: Int = 10) async {
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
    
    @AccentColor
    private var tint
    
    @Query
    private var notes: [_Note]
    
    @Binding
    var noteToEdit: _Note?
        
    init(noteToEdit: Binding<_Note?>, uuids: [UUID?]?, order: SortOrder) {
        var descriptor = FetchDescriptor(sortBy: [SortDescriptor(\_Note.createdAt, order: order)])
        if let uuids {
            descriptor.predicate = #Predicate<_Note> {  uuids.contains($0.memoryUuid) }
        }
        self._noteToEdit = noteToEdit
        self._notes = .init(descriptor)
    }
    
    var body: some View {
        List {
            ForEach(notes) { note in
                Button {
                    noteToEdit = note
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
