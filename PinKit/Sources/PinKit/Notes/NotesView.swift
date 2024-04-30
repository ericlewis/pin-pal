import SwiftUI

struct NotesView: View {
    
    @Environment(NavigationStore.self) 
    private var navigationStore
    
    @Environment(NotesRepository.self)
    private var repository
    
    @State
    private var fileImporterPresented = false
    
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
                        Menu("Create note", systemImage: "plus") {
                            Button("Create", systemImage: "note.text.badge.plus") {
                                self.navigationStore.activeNote = .create()
                            }
                            Button("Import", systemImage: "square.and.arrow.down") {
                                self.fileImporterPresented = true
                            }
                        } primaryAction: {
                            self.navigationStore.activeNote = .create()
                        }
                    }
                }
                .navigationTitle("Notes")
        }
        .sheet(item: $navigationStore.activeNote) { note in
            NoteComposerView(note: note)
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
                        self.navigationStore.activeNote = .init(text: str, title: success.lastPathComponent)
                    case let .failure(failure):
                        break
                    }
                } catch {
                    print(error)
                }
            }
        }
        .task(repository.initial)
    }
}

#Preview {
    NotesView()
        .environment(NotesRepository())
        .environment(NavigationStore())
}
