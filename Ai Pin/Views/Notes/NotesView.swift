import SwiftUI
import OSLog

struct MemoryView: View {
    @EnvironmentObject private var colorStore: ColorStore
    
    let memory: Memory
    
    var body: some View {
        if let note = memory.data.note {
            VStack(alignment: .leading, spacing: 10) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(note.title)
                        .foregroundStyle(colorStore.accentColor)
                        .font(.headline)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .overlay(alignment: .topTrailing) {
                            if memory.favorite {
                                Image(systemName: "heart")
                                    .symbolVariant(.fill)
                                    .foregroundStyle(.red)
                            }
                        }
                    Text(.init(note.text))
                }
                
                Text(memory.userCreatedAt, format: .dateTime)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct NotesView: View {
    @EnvironmentObject private var colorStore: ColorStore
    
    struct ViewState {
        var notes: [Memory] = []
        var isLoading = false
    }
    
    @State private var state = ViewState()
    
    @State private var selectedNoteId = ""
    @State private var selectedNote = Note(text: "", title: "")
    
    @Environment(NavigationStore.self) private var navigationStore
    
    var body: some View {
        @Bindable var navigationStore = navigationStore
        
        NavigationStack(path: $navigationStore.notesNavigationPath) {
            List {
                ForEach(state.notes, id: \.uuid) { memory in
                    MemoryView(memory: memory)
                        .swipeActions(edge: .leading, allowsFullSwipe: true) {
                            Group {
                                if memory.favorite {
                                    Button("Unfavorite", systemImage: "heart.slash") {
                                        Task {
                                            let _ = try await API.shared.unfavorite(memory: memory)
                                            await load()
                                        }
                                    }
                                } else {
                                    Button("Favorite", systemImage: "heart") {
                                        Task {
                                            let _ = try await API.shared.favorite(memory: memory)
                                            await load()
                                        }
                                    }
                                }
                            }
                            .tint(.pink)
                        }
                        .environmentObject(colorStore)
                        .onTapGesture {
                            selectedNoteId = memory.uuid
                            selectedNote = memory.data.note ?? Note(text: "", title: "")
                            self.navigationStore.editNotePresented = true
                        }
                }
                .onDelete { indexSet in
                    for i in indexSet {
                        withAnimation {
                            let note = state.notes.remove(at: i)
                            Task {
                                try await API.shared.delete(memory: note)
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
                        self.navigationStore.newNotePresented = true
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
        .sheet(isPresented: $navigationStore.newNotePresented, onDismiss: {
            Task {
                await load()
            }
        }) {
            AddNoteView()
        }
        .sheet(isPresented: $navigationStore.editNotePresented, onDismiss: {
            Task {
                await load()
            }
        }) {
            NotesEditView(noteId: selectedNoteId, note: selectedNote)
                .environmentObject(colorStore)
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
            let notes = try await API.shared.notes().content
            withAnimation {
                self.state.notes = notes
            }
        } catch APIError.notAuthorized {
            self.navigationStore.authenticationPresented = true
        } catch {
            let logger = Logger()
            logger.error("\(error.localizedDescription)")
        }
    }
}

#Preview {
    NotesView()
}
