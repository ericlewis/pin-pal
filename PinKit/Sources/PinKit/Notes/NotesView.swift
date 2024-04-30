import SwiftUI

public struct NotesView: View {

    @Environment(NavigationStore.self) 
    private var navigationStore
 
    @Environment(\.expensiveTokenRefresh)
    private var refreshToken
    
    @Environment(NotesRepository.self)
    private var notesRepository
    
    public init() {}
    
    public var body: some View {
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
            }
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
            .refreshable(action: notesRepository.reload)
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
        .environment(HumaneCenterService.live())
}
