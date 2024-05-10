import SwiftUI
import SwiftData

struct NotesView: View {
    
    enum FilterType {
        case all
        case favorites
    }
    
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
    private var filter = Note.all()
    
    @State
    private var filterType = FilterType.all
    
    @State
    private var sort = SortDescriptor<Note>(\.createdAt, order: .reverse)
    
    @State
    private var order = SortOrder.reverse
    
    var predicate: Predicate<Note> {
        if filterType == .all {
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
        var filter = filter
        let _ = filter.sortBy = [sort]
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
                        Toggle("All Items", systemImage: "note.text", isOn: toggle(filter: .all))
                        Section {
                            Toggle("Favorites", systemImage: "heart", isOn: toggle(filter: .favorites))
                        }
                    }
                    .symbolVariant(filterType == .all ? .none : .fill)
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        Toggle("Name", isOn: toggle(sortedBy: \.name))
                        Toggle("Body", isOn: toggle(sortedBy: \.body))
                        Toggle("Created At", isOn: toggle(sortedBy: \.createdAt))
                        Toggle("Modified At", isOn: toggle(sortedBy: \.modifiedAt))
                        Section("Order") {
                            Picker("Order", selection: $order) {
                                Label("Ascending", systemImage: "arrow.up").tag(SortOrder.forward)
                                Label("Descending", systemImage: "arrow.down").tag(SortOrder.reverse)
                            }
                            .onChange(of: order) {
                                withAnimation(.snappy) {
                                    sort.order = order
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
        .task(id: query) {
            do {
                try await Task.sleep(for: .milliseconds(300))
                let intent = SearchNotesIntent()
                intent.query = query
                intent.service = service
                guard !query.isEmpty, let result = try await intent.perform().value else {
                    filter = Note.all()
                    return
                }
                let ids = result.map(\.id)
                let predicate = #Predicate<Note> {
                    ids.contains($0.parentUUID)
                }
                filter = FetchDescriptor(predicate: predicate)
            } catch is CancellationError {
                
            } catch {
                filter = Note.all()
                print(error)
            }
        }
    }
    
    func toggle(sortedBy: KeyPath<Note, String>) -> Binding<Bool> {
        Binding(
            get: { sort.keyPath == sortedBy  },
            set: {
                if $0 {
                    withAnimation(.snappy) {
                        sort = SortDescriptor<Note>(sortedBy, order: order)
                    }
                }
            }
        )
    }
    
    func toggle(sortedBy: KeyPath<Note, Date>) -> Binding<Bool> {
        Binding(
            get: { sort.keyPath == sortedBy  },
            set: {
                if $0 {
                    withAnimation(.snappy) {
                        sort = SortDescriptor<Note>(sortedBy, order: order)
                    }
                }
            }
        )
    }
    
    func toggle(filter: FilterType) -> Binding<Bool> {
        Binding(
            get: {
                filterType == filter
            },
            set: { isOn in
                if isOn, filterType != filter {
                    withAnimation(.snappy) {
                        self.filterType = filter
                    }
                } else {
                    withAnimation(.snappy) {
                        self.filterType = .all
                    }
                }
            }
        )
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

protocol Sortable {}

extension Date: Sortable {}
