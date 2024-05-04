import SwiftUI
import SwiftData
import CollectionConcurrencyKit

struct NotesView: View {
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service

    @State
    private var searchQuery = ""
    
    @State
    private var searchResults: [UUID]?
    
    @State
    private var fileImporterPresented = false
    
    @State
    private var isLoading = false
    
    var body: some View {
        @Bindable var navigationStore = navigationStore
        NavigationStack {
            NotesList(uuids: searchResults, order: .reverse, isLoading: isLoading)
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Menu("Create note", systemImage: "plus") {
                            Button("Create", systemImage: "note.text.badge.plus") {
                                self.navigationStore.activeNote = Note.newNote()
                            }
                            Button("Import", systemImage: "square.and.arrow.down") {
                                self.navigationStore.isFileImporterPresented = true
                            }
                        } primaryAction: {
                            self.navigationStore.activeNote = Note.newNote()
                        }
                    }
                }
                .searchable(text: $searchQuery)
                .navigationTitle("Notes")
        }
        .sheet(item: $navigationStore.activeNote) {
            NoteComposerView(editableNote: $0)
        }
        .fileImporter(
            isPresented: $navigationStore.isFileImporterPresented,
            allowedContentTypes: [.plainText],
            onCompletion: handleFileImport(result:)
        )
        .task(id: searchQuery, search)
    }
    
    private func handleFileImport(result: Result<URL, Error>) {
        Task.detached {
            do {
                switch result {
                case let .success(success):
                    let str = try String(contentsOf: success)
                    self.navigationStore.activeNote = .init(title: success.lastPathComponent, text: str, createdAt: .now)
                case let .failure(failure):
                    break
                }
            } catch {
                print(error)
            }
        }
    }
    
    private func search() async {
        do {
            try await Task.sleep(for: .milliseconds(300))
            guard !searchQuery.isEmpty else {
                withAnimation {
                    self.searchResults = nil
                }
                return
            }
            let res = try await service.search(searchQuery, .notes).memories ?? []
            searchResults = res.map(\.uuid)
        } catch is CancellationError {
            // noop
        } catch {
            let err = error as NSError
            if err.domain != NSURLErrorDomain, err.code != NSURLErrorCancelled {
                print(error)
            }
        }
    }
}
