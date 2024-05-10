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

    var predicate: Predicate<Note> {
        if app.noteFilter.type == .all {
            return #Predicate<Note> { _ in
                true
            }
        } else {
            return #Predicate<Note> {
                $0.isFavorite
            }
        }
    }

    var body: some View {
        @Bindable var navigation = navigation
        @Bindable var noteFilter = app.noteFilter
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
                SyncStatusView(current: \.numberOfNotesSynced, total: \.totalNotesToSync)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu("New Note", systemImage: "plus") {
                        Button("Create", systemImage: "note.text.badge.plus", intent: OpenNewNoteIntent())
                        Button("Import", systemImage: "square.and.arrow.down", intent: OpenFileImportIntent())
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
            .navigationTitle("Notes")
        }
        .sheet(item: $navigation.activeNote) { note in
            NoteComposerView(note: note)
        }
        .fileImporter(
            isPresented: $navigation.fileImporterPresented,
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
        .task(id: query, search)
    }
    
    func search() async {
        do {
            try await Task.sleep(for: .milliseconds(300))
            let intent = SearchNotesIntent()
            intent.query = query
            intent.service = service
            guard !query.isEmpty, let result = try await intent.perform().value else {
                app.noteFilter.filter = Note.all()
                return
            }
            let ids = result.map(\.id)
            let predicate = #Predicate<Note> {
                ids.contains($0.parentUUID)
            }
            app.noteFilter.filter = FetchDescriptor(predicate: predicate)
        } catch is CancellationError {
            
        } catch {
            app.noteFilter.filter = Note.all()
            print(error)
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
}

struct SortNotesToggle: View {
    
    let name: LocalizedStringKey
    let sortBy: KeyPath<Note, String>?
    let sortBy2: KeyPath<Note, Date>?

    init(_ name: LocalizedStringKey, sortBy: KeyPath<Note, String>) {
        self.name = name
        self.sortBy = sortBy
        self.sortBy2 = nil
    }
    
    init(_ name: LocalizedStringKey, sortBy: KeyPath<Note, Date>) {
        self.name = name
        self.sortBy = nil
        self.sortBy2 = sortBy
    }
    
    @Environment(AppState.self)
    private var app
    
    var body: some View {
        if let sortBy2 {
            Toggle(name, isOn: app.noteFilter.sort.keyPath == sortBy, intent: SortNotesIntent(sortBy: sortBy2))
        } else if let sortBy {
            Toggle(name, isOn: app.noteFilter.sort.keyPath == sortBy, intent: SortNotesIntent(sortBy: sortBy))
        }
    }
}
