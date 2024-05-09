import SwiftUI
import AppIntents
import SwiftData

struct SearchableNotesListView: View {

    @Environment(\.isSearching)
    private var isSearching
    
    @Environment(HumaneCenterService.self)
    private var service

    @Environment(\.database)
    private var database

    var isLoading: Bool
    var isFirstLoad: Bool
    
    @Query
    var notes: [_Note]
    
    init(filter: FetchDescriptor<_Note>, isLoading: Bool, isFirstLoad: Bool) {
        self._notes = .init(filter)
        self.isLoading = isLoading
        self.isFirstLoad = isFirstLoad
    }
    
    var body: some View {
        List {
            ForEach(notes) { note in
                Button(intent: OpenNoteIntent(note: note)) {
                    LabeledContent {} label: {
                        Text(note.name)
                        Text(note.body)
                        DateTextView(date: note.createdAt)
                    }
                    .tint(.primary)
                    .task {
                        do {
                            try await service.memory(note.parentUUID)
                        } catch {
                            await database.delete(note)
                            try? await database.save()
                            
                            // the merge doesn't happen correctly so we manually clean it up
                            note.modelContext?.delete(note)
                        }
                    }
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    FavoriteNoteButton(note: note)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    DeleteNoteButton(note: note)
                }
            }
        }
        .overlay {
            if notes.isEmpty, isSearching, !isLoading {
                ContentUnavailableView.search
            } else if notes.isEmpty, isLoading {
                ProgressView()
            } else if notes.isEmpty, !isSearching, !isFirstLoad {
                ContentUnavailableView("No notes yet", systemImage: "note.text")
            }
        }
    }
}

struct FavoriteNoteButton: View {
    
    let note: _Note
    
    var body: some View {
        let favorite = note.isFavorite
        Button(
            favorite ? "Unfavorite" : "Favorite",
            systemImage: "heart",
            intent: FavoriteNotesIntent(action: favorite ? .remove : .add, notes: [note])
        )
        .symbolVariant(favorite ? .slash : .none)
        .tint(.pink)
    }
}

struct DeleteNoteButton: View {
    
    let note: _Note
    
    var body: some View {
        Button(
            "Delete",
            systemImage: "trash",
            role: .destructive,
            intent: DeleteNotesIntent(entities: [note], confirmBeforeDeleting: false)
        )
        .tint(.red)
    }
}
