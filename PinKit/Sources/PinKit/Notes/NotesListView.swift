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

