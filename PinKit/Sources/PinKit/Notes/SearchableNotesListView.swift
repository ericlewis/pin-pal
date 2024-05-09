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
    
    @AccentColor
    private var accentColor

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
                        LabeledContent {
                            if note.isFavorite {
                                Image(systemName: "heart")
                                    .symbolVariant(.fill)
                                    .imageScale(.small)
                                    .foregroundStyle(.pink)
                                    .offset(x: 10)
                            }
                        } label: {
                            Text(note.name)
                                .font(.headline)
                                .foregroundStyle(accentColor)
                        }
                            
                        Text(note.body)
                            .foregroundStyle(.primary)
                        LabeledContent {
                            
                        } label: {
                            DateTextView(date: note.modifiedAt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .textSelection(.enabled)
                    .tint(.primary)
                    .task {
                        do {
                            try await service.memory(note.parentUUID)
                        } catch is CancellationError {
                            
                        } catch APIError.notAuthorized {
                            
                        } catch {
                            let err = (error as NSError)
                            guard err.domain == NSURLErrorDomain, err.code == NSURLErrorCancelled else {
                                return
                            }
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
                ProgressView("This may take a little while.")
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
