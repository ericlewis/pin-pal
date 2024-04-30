import SwiftUI

struct NotesView: View {

    @Environment(NavigationStore.self) 
    private var navigationStore

    @Environment(NotesRepository.self)
    private var repository
        
    var body: some View {
        @Bindable var navigationStore = navigationStore
        NavigationStack(path: $navigationStore.notesNavigationPath) {
            List {
                ForEach(repository.content) { memory in
                    Button {
                        self.navigationStore.activeNote = memory.get()
                    } label: {
                        ContentCellView(content: memory)
                    }
                    .foregroundStyle(.primary)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button(memory.favorite ? "Unfavorite" : "Favorite", systemImage: "heart") {
                            Task {
                                await repository.toggleFavorite(content: memory)
                            }
                        }
                        .tint(.pink)
                        .symbolVariant(memory.favorite ? .slash : .none)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        await repository.remove(offsets: indexSet)
                    }
                }
                if repository.hasMoreData {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .task {
                        await repository.loadMore()
                    }
                }
            }
            .refreshable(action: repository.reload)
            .searchable(text: .constant(""))
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    EditButton()
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Create note", systemImage: "plus") {
                        self.navigationStore.activeNote = Note.create()
                    }
                }
            }
            .navigationTitle("Notes")
        }
        .overlay {
            if !repository.hasContent, repository.isLoading {
                ProgressView()
            } else if !repository.hasContent, repository.isFinished {
                ContentUnavailableView("No notes yet", systemImage: "note.text")
            }
        }
        .sheet(item: $navigationStore.activeNote) { note in
            NoteComposerView(note: note)
        }
        .task(repository.initial)
    }
}

#Preview {
    NotesView()
        .environment(NotesRepository())
        .environment(NavigationStore())
}
