import SwiftUI

struct NotesView: View {
    
    @Environment(NavigationStore.self) 
    private var navigationStore
    
    @Environment(NotesRepository.self)
    private var repository
    
    @State
    private var query = ""
    
    var body: some View {
        @Bindable var navigationStore = navigationStore
        NavigationStack(path: $navigationStore.notesNavigationPath) {
            SearchableNotesListView(query: $query)
                .refreshable(action: repository.reload)
                .searchable(text: $query)
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
