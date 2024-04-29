import SwiftUI
import OSLog

public struct NotesView: View {
    struct ViewState {
        var notes: [ContentEnvelope] = []
        var isLoading = false
    }
    
    @State 
    private var state = ViewState()
    
    @Environment(NavigationStore.self) 
    private var navigationStore
    
    @Environment(HumaneCenterService.self)
    private var api
    
    public init() {}
    
    public var body: some View {
        @Bindable var navigationStore = navigationStore
        NavigationStack(path: $navigationStore.notesNavigationPath) {
            List {
                ForEach(state.notes, id: \.uuid) { memory in
                    Button {
                        self.navigationStore.activeNote = memory.get()
                    } label: {
                        ContentCellView(content: memory)
                    }
                    .foregroundStyle(.primary)
                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                        Group {
                            if memory.favorite {
                                Button("Unfavorite", systemImage: "heart.slash") {
                                    Task {
                                        let _ = try await api.unfavorite(memory)
                                        await load()
                                    }
                                }
                            } else {
                                Button("Favorite", systemImage: "heart") {
                                    Task {
                                        let _ = try await api.favorite(memory)
                                        await load()
                                    }
                                }
                            }
                        }
                        .tint(.pink)
                    }
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        withAnimation {
                            let note = state.notes.remove(at: i)
                            Task {
                                try await api.delete(note)
                            }
                        }
                    }
                }
            }
            .searchable(text: .constant(""))
            .searchPresentationToolbarBehavior(.avoidHidingContent)
            .refreshable {
                await load()
            }
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
            if !state.isLoading && state.notes.isEmpty {
                ContentUnavailableView("No notes yet", systemImage: "note.text")
            } else if state.isLoading && state.notes.isEmpty {
                ProgressView()
            }
        }
        .sheet(item: $navigationStore.activeNote, onDismiss: {
            Task {
                await load()
            }
        }) { note in
            NoteComposerView(note: note)
        }
        .task {
            state.isLoading = true
            while !Task.isCancelled {
                await load()
                state.isLoading = false
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }
    
    func load() async {
        do {
            let notes = try await api.notes().content
            withAnimation {
                self.state.notes = notes
            }
        } catch APIError.notAuthorized {
            self.navigationStore.authenticationPresented = true
        } catch {
            print("\(error.localizedDescription)")
        }
    }
}

#Preview {
    NotesView()
        .environment(HumaneCenterService.live())
}
