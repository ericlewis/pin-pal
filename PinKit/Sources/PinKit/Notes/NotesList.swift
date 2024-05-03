import SwiftUI
import SwiftData

struct NotesList: View {
    
    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(\.isSearching)
    private var isSearching

    @Query
    private var notes: [Note]
    
    let isLoading: Bool
    
    init(uuids: [UUID]?, order: SortOrder, isLoading: Bool) {
        var descriptor = FetchDescriptor(sortBy: [SortDescriptor(\Note.createdAt, order: order)])
        if let uuids {
            descriptor.predicate = #Predicate<Note> {
                if let memory = $0.memory {
                    return uuids.contains(memory.uuid)
                } else {
                    return false
                }
            }
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
                    NoteCellView(note: note)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    FavoriteButton(note: note)
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
                    if let uuid = note.memory?.uuid {
                        try await service.deleteById(uuid)
                    }
                }
                try await database.save()
            } catch {
                print("Error deleting note: \(error)")
            }
        }
    }
}

