import SwiftUI

struct SearchableNotesListView: View {
    
    @Environment(NotesRepository.self)
    private var repository
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(\.isSearching)
    private var isSearching
    
    @Binding
    var query: String
    
    var body: some View {
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
            if !isSearching, repository.isFinished, repository.hasMoreData {
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
            if isSearching, !repository.isLoading, !repository.hasContent {
                ContentUnavailableView.search
            } else if !repository.hasContent, repository.isLoading {
                ProgressView()
            } else if !repository.hasContent, !isSearching, repository.isFinished {
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

