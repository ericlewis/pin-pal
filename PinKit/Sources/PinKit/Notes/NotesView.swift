import SwiftUI

struct NotesView: View {

    @Environment(NavigationStore.self) 
    private var navigationStore

    @Environment(NotesRepository.self)
    private var notesRepository
        
    var body: some View {
        @Bindable var navigationStore = navigationStore
        NavigationStack(path: $navigationStore.notesNavigationPath) {
            List {
                ForEach(notesRepository.content, id: \.uuid) { memory in
                    Button {
                        self.navigationStore.activeNote = memory.get()
                    } label: {
                        ContentCellView(content: memory)
                    }
                    .foregroundStyle(.primary)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Button(memory.favorite ? "Unfavorite" : "Favorite", systemImage: "heart") {
                            Task {
                                await notesRepository.toggleFavorite(content: memory)
                            }
                        }
                        .tint(.pink)
                        .symbolVariant(memory.favorite ? .slash : .none)
                    }
                }
                .onDelete { indexSet in
                    Task {
                        await notesRepository.remove(offsets: indexSet)
                    }
                }
                if notesRepository.hasMoreData {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .task {
                        await notesRepository.loadMore()
                    }
                }
            }
            .refreshable(action: notesRepository.reload)
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
            if !notesRepository.hasContent, notesRepository.isLoading {
                ProgressView()
            } else if !notesRepository.hasContent, notesRepository.isFinished {
                ContentUnavailableView("No notes yet", systemImage: "note.text")
            }
        }
        .sheet(item: $navigationStore.activeNote) { note in
            NoteComposerView(note: note)
        }
        .task(notesRepository.initial)
    }
}

#Preview {
    NotesView()
        .environment(NotesRepository())
        .environment(NavigationStore())
}
