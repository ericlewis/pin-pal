import SwiftUI
import SwiftData

struct NotesView: View {
    
    @Environment(NavigationStore.self)
    private var navigation

    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service

    @State
    private var isLoading = false
    
    @State
    private var isFirstLoad = true
    
    @State
    private var query = ""
    
    @State
    private var filter = _Note.all()

    var body: some View {
        @Bindable var navigationStore = navigation
        NavigationStack(path: $navigationStore.notesNavigationPath) {
            SearchableNotesListView(
                filter: filter,
                isLoading: isLoading,
                isFirstLoad: isFirstLoad
            )
            .refreshable(action: initial)
            .searchable(text: $query)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Menu("Options", systemImage: "ellipsis") {
                        Toggle("Testing", isOn: .constant(true))
                        Picker("Sort", systemImage: "arrow.up.arrow.down", selection: .constant("Created At")) {
                            Text("Created At").tag("Created At")
                            Text("Last Modified At").tag("Last Modified At")
                        }
                        .pickerStyle(.menu)
                    }
                    .symbolVariant(.circle)
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu("Create note", systemImage: "plus") {
                        Button("Create", systemImage: "note.text.badge.plus", intent: OpenNewNoteIntent())
                        Button("Import", systemImage: "square.and.arrow.down") {
                            self.navigation.fileImporterPresented = true
                        }
                    } primaryAction: {
                        self.navigation.activeNote = .create()
                    }
                }
            }
            .navigationTitle("Notes")
        }
        .sheet(item: $navigationStore.activeNote) { note in
            NoteComposerView(note: note)
        }
        .fileImporter(
            isPresented: $navigationStore.fileImporterPresented,
            allowedContentTypes: [.plainText]
        ) { result in
            Task.detached {
                do {
                    switch result {
                    case let .success(success):
                        let str = try String(contentsOf: success)
                        self.navigation.activeNote = .init(text: str, title: success.lastPathComponent)
                    case let .failure(failure):
                        break
                    }
                } catch {
                    print(error)
                }
            }
        }
        .task(initial)
        .task(id: query) {
            do {
                try await Task.sleep(for: .milliseconds(300))
                let intent = SearchNotesIntent()
                intent.query = query
                intent.service = service
                guard !query.isEmpty, let result = try await intent.perform().value else {
                    filter = _Note.all()
                    return
                }
                let ids = result.map(\.id)
                let predicate = #Predicate<_Note> {
                    ids.contains($0.parentUUID)
                }
                filter = FetchDescriptor(predicate: predicate)
            } catch is CancellationError {
                
            } catch {
                filter = _Note.all()
                print(error)
            }
        }
    }
    
    func initial() async {
        isLoading = true
        do {
            let intent = LoadNotesIntent(page: 0)
            intent.database = database
            intent.service = service
            try await intent.perform()
        } catch {
            print(error)
        }
        isLoading = false
        isFirstLoad = false
    }
}
