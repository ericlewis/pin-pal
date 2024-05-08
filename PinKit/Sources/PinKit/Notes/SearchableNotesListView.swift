import SwiftUI
import AppIntents
import SwiftData

struct SearchableNotesListView: View {
    
    @Environment(NotesRepository.self)
    private var repository
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(\.isSearching)
    private var isSearching

    @Binding
    var query: String
    
    @Query(_Note.all())
    var notes: [_Note]
    
    var body: some View {
        List {
            ForEach(notes) { note in
                Button(intent: OpenNoteIntent(note: .init(from: note))) {
                    LabeledContent {} label: {
                        Text(note.name)
                        Text(note.body)
                        DateTextView(date: note.createdAt)
                    }
                    .tint(.primary)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    let favorite = note.isFavorite
                    Button(
                        favorite ? "Unfavorite" : "Favorite",
                        systemImage: "heart",
                        intent: FavoriteNotesIntent(action: favorite ? .remove : .add, notes: [.init(from: note)])
                    )
                    .symbolVariant(favorite ? .slash : .none)
                    .tint(.pink)
                }
            }
            .onDelete { indexSet in
                Task {
                    await repository.remove(offsets: indexSet)
                }
            }
            if !isSearching, repository.isFinished, !notes.isEmpty, repository.hasMoreData {
                HStack {
                    Spacer()
                    ProgressView()
                    Spacer()
                }
                .task {
                    await repository.loadMore()
                }
                .deleteDisabled(true)
            }
        }
        .overlay {
            if notes.isEmpty, isSearching, !repository.isLoading {
                ContentUnavailableView.search
            } else if notes.isEmpty, repository.isLoading {
                ProgressView()
            } else if notes.isEmpty, !isSearching, repository.isFinished {
                ContentUnavailableView("No notes yet", systemImage: "note.text")
            }
        }
        .task(id: query + (isSearching ? "true" : "false")) {
            if isSearching, !query.isEmpty {
                await repository.search(query: query)
            } else if query.isEmpty {
                await repository.reload()
            }
        }
    }
}

