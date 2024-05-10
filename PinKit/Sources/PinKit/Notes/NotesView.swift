import SwiftUI
import SwiftData
import AppIntents

struct NotesView: View {

    @Environment(AppState.self)
    private var app
    
    @Environment(Navigation.self)
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
    private var ids: [UUID] = []

    var body: some View {
        @Bindable var navigation = navigation
        var filter = app.noteFilter.filter
        let _ = filter.sortBy = [app.noteFilter.sort]
        let _ = filter.predicate = predicate
        NavigationStack {
            SearchableNotesListView(
                filter: filter,
                isLoading: isLoading,
                isFirstLoad: isFirstLoad
            )
            .refreshable(action: load)
            .searchable(text: $query)
            .overlay(alignment: .bottom) {
                SyncStatusView(
                    current: \.numberOfNotesSynced,
                    total: \.totalNotesToSync
                )
            }
            .toolbar {
                toolbar
            }
            .navigationTitle("Notes")
        }
        .sheet(item: $navigation.activeNote) { note in
            NoteComposerView(note: note)
        }
        .fileImporter(
            isPresented: $navigation.fileImporterPresented,
            allowedContentTypes: [.plainText],
            onCompletion: handleImport
        )
        .task(initial)
        .task(id: query, search)
    }
    
    var predicate: Predicate<Note> {
        if !query.isEmpty {
            return #Predicate<Note> {
                ids.contains($0.parentUUID)
            }
        } else if app.noteFilter.type == .all {
            return #Predicate<Note> { _ in
                true
            }
        } else {
            return #Predicate<Note> {
                $0.isFavorite
            }
        }
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        @Bindable var noteFilter = app.noteFilter
        ToolbarItem(placement: .primaryAction) {
            Menu("New Note", systemImage: "plus") {
                Button("New Note", systemImage: "note.text.badge.plus", intent: OpenNewNoteIntent())
                Button("Import Text", systemImage: "square.and.arrow.down", intent: OpenFileImportIntent())
            } primaryAction: {
                self.navigation.activeNote = .create()
            }
        }
        ToolbarItemGroup(placement: .secondaryAction) {
            Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                Toggle(isOn: noteFilter.type == .all, intent: FilterNotesIntent(filter: .all)) {
                    Label("All Items", systemImage: "note.text")
                }
                Section {
                    Toggle(isOn: noteFilter.type == .favorites, intent: FilterNotesIntent(filter: .favorites)) {
                        Label("Favorites", systemImage: "heart")
                    }
                }
            }
            .symbolVariant(noteFilter.type == .all ? .none : .fill)
            Menu("Sort", systemImage: "arrow.up.arrow.down") {
                SortNotesToggle("Name", sortBy: \.name)
                SortNotesToggle("Body", sortBy: \.body)
                SortNotesToggle("Created At", sortBy: \.createdAt)
                SortNotesToggle("Modified At", sortBy: \.modifiedAt)
                Section("Order") {
                    Picker("Order", selection: $noteFilter.order) {
                        Label("Ascending", systemImage: "arrow.up").tag(SortOrder.forward)
                        Label("Descending", systemImage: "arrow.down").tag(SortOrder.reverse)
                    }
                    .onChange(of: noteFilter.order) {
                        withAnimation(.snappy) {
                            noteFilter.sort.order = noteFilter.order
                        }
                    }
                }
            }
        }
    }
}

extension NotesView {
    func search() async {
        do {
            isLoading = true
            try await Task.sleep(for: .milliseconds(300))
            let intent = SearchNotesIntent()
            intent.query = query
            intent.service = service
            guard !query.isEmpty, let result = try await intent.perform().value else {
                self.ids = []
                self.isLoading = false
                return
            }
            withAnimation(.snappy) {
                self.ids = result.map(\.id)
                isLoading = false
            }
        } catch is CancellationError {
            
        } catch {
            
        }
    }
 
    func initial() async {
        guard !isLoading, isFirstLoad else { return }
        Task.detached {
            await load()
        }
    }
    
    func load() async {
        isLoading = true
        do {
            let intent = SyncNotesIntent()
            intent.database = database
            intent.service = service
            intent.app = app
            try await intent.perform()
        } catch {
            print(error)
        }
        isLoading = false
        isFirstLoad = false
    }
    
    func handleImport(_ result: Result<URL, any Error>) {
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
}
