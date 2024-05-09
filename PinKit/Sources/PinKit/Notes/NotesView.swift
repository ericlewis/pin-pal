import SwiftUI
import SwiftData

struct NotesView: View {
    
    enum FilterType {
        case all
        case favorites
    }
    
    @Environment(AppState.self)
    private var app
    
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
    
    @State
    private var filterType = FilterType.all
    
    @State
    private var sort = SortDescriptor<_Note>(\.createdAt, order: .reverse)
    
    @State
    private var order = SortOrder.reverse
    
    var predicate: Predicate<_Note> {
        if filterType == .all {
            return #Predicate<_Note> { _ in
                true
            }
        } else {
            return #Predicate<_Note> {
                $0.isFavorite
            }
        }
    }

    var body: some View {
        @Bindable var navigationStore = navigation
        var filter = filter
        let _ = filter.sortBy = [sort]
        let _ = filter.predicate = predicate
        NavigationStack(path: $navigationStore.notesNavigationPath) {
            SearchableNotesListView(
                filter: filter,
                isLoading: isLoading,
                isFirstLoad: isFirstLoad
            )
            .refreshable(action: load)
            .searchable(text: $query)
            .overlay(alignment: .bottom) {
                if app.currentTotalToSync > 0, app.currentSyncTotal > 0 {
                    let current = Double(app.currentSyncTotal)
                    let total = Double(app.currentTotalToSync)
                    ProgressView(value:  current / total)
                        .padding(.horizontal, -5)
                }
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
                        Toggle("All Items", systemImage: "note.text", isOn: Binding(
                            get: {
                                filterType == .all
                            },
                            set: {
                                if $0 {
                                    self.filterType = .all
                                }
                            }
                        ))
                        Section {
                            Toggle("Favorites", systemImage: "heart", isOn: Binding(
                                get: {
                                    filterType == .favorites
                                },
                                set: {
                                    if $0 {
                                        self.filterType = .favorites
                                    }
                                }
                            ))
                        }
                    }
                    .symbolVariant(filterType == .all ? .none : .fill)
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
                        Toggle("Name", isOn: Binding(
                            get: { sort.keyPath == \_Note.name  },
                            set: {
                                if $0 {
                                    withAnimation(.snappy) {
                                        sort = SortDescriptor<_Note>(\.name, order: order)
                                    }
                                }
                            }
                        ))
                        Toggle("Body", isOn: Binding(
                            get: { sort.keyPath == \_Note.body  },
                            set: {
                                if $0 {
                                    withAnimation(.snappy) {
                                        sort = SortDescriptor<_Note>(\.body, order: order)
                                    }
                                }
                            }
                        ))
                        Toggle("Created At", isOn: Binding(
                            get: { sort.keyPath == \_Note.createdAt  },
                            set: {
                                if $0 {
                                    withAnimation(.snappy) {
                                        sort = SortDescriptor<_Note>(\.createdAt, order: order)
                                    }
                                }
                            }
                        ))
                        Toggle("Modified At", isOn: Binding(
                            get: { sort.keyPath == \_Note.modifiedAt  },
                            set: {
                                if $0 {
                                    withAnimation(.snappy) {
                                        sort = SortDescriptor<_Note>(\.modifiedAt, order: order)
                                    }
                                }
                            }
                        ))
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
