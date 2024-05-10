import SwiftUI

struct CaptureImageContentModeKey: EnvironmentKey {
    static var defaultValue: ContentMode = .fill
}

extension EnvironmentValues {
    var imageContentMode: ContentMode {
        get { self[CaptureImageContentModeKey.self] }
        set { self[CaptureImageContentModeKey.self] = newValue }
    }
}

struct CapturesView: View {
    
    enum Filter {
        case all
        case photo
        case video
        case favorites
    }
    
    @Environment(CapturesRepository.self)
    private var repository
    
    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(AppState.self)
    private var app

    @State
    private var query = ""
    
    @State
    private var isLoading = false
    
    @State
    private var isFirstLoad = true
    
    @State
    private var filter = Filter.all
    
    @State
    private var order = SortOrder.reverse
    
    @State
    private var sort = SortDescriptor<Capture>(\.createdAt, order: .reverse)
    
    @State
    private var imageContentMode = ContentMode.fill
    
    var predicate: Predicate<Capture> {
        switch filter {
        case .all:
            return #Predicate<Capture> { _ in
                true
            }
        case .photo:
            return #Predicate<Capture> {
                $0.isPhoto
            }
        case .video:
            return #Predicate<Capture> {
                !$0.isPhoto
            }
        case .favorites:
            return #Predicate<Capture> {
                $0.isFavorite
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            var descriptor = Capture.all()
            let _ = descriptor.predicate = predicate
            let _ = descriptor.sortBy = [sort]
            QueryGridView(descriptor: descriptor) { capture in
                NavigationLink {
                    // CaptureDetailView(capture: capture)
                } label: {
                    CaptureCellView(capture: capture)
                        .environment(\.imageContentMode, imageContentMode)
                }
                .contextMenu {
                    CaptureMenuContents(capture: capture)
                } preview: {
                    CaptureImageView(capture: capture)
                }
                .buttonStyle(.plain)
            } placeholder: {
                ContentUnavailableView("No captures yet", systemImage: "camera.aperture")
            }
            .onChange(of: order) {
                sort.order = order
            }
            .environment(\.isLoading, isLoading)
            .environment(\.isFirstLoad, isFirstLoad)
            .overlay(alignment: .bottom) {
                SyncStatusView(
                    current: \.numberOfCapturesSynced,
                    total: \.totalCapturesToSync
                )
            }
            .refreshable(action: load)
            .searchable(text: $query)
            .navigationTitle("Captures")
            .toolbar {
                ToolbarItemGroup(placement: .primaryAction) {
                    Button("Select") {
                        
                    }
                    .disabled(true)
                }
                ToolbarItemGroup(placement: .secondaryAction) {
                    if imageContentMode == .fill {
                        Button("Aspect Ratio Grid", systemImage: "rectangle.arrowtriangle.2.inward") {
                            withAnimation(.snappy) {
                                imageContentMode = .fit
                            }
                        }
                    } else {
                        Button("Square Photo Grid", systemImage: "rectangle.arrowtriangle.2.outward") {
                            withAnimation(.snappy) {
                                imageContentMode = .fill
                            }
                        }
                    }
                    Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                        Toggle("All Items", systemImage: "photo.on.rectangle", isOn: toggle(filter: .all))
                        Section {
                            Toggle("Favorites", systemImage: "heart", isOn: toggle(filter: .favorites))
                            Toggle("Photos", systemImage: "photo", isOn: toggle(filter: .photo))
                            Toggle("Videos", systemImage: "video", isOn: toggle(filter: .video))
                        }
                    }
                    .symbolVariant(filter == .all ? .none : .fill)
                    Menu("Sort", systemImage: "arrow.up.arrow.down") {
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
        }
        .task(initial)
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
            let intent = SyncCapturesIntent()
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

    func toggle(sortedBy: KeyPath<Capture, Date>) -> Binding<Bool> {
        Binding(
            get: { sort.keyPath == sortedBy  },
            set: {
                if $0 {
                    withAnimation(.snappy) {
                        sort = SortDescriptor<Capture>(sortedBy, order: order)
                    }
                }
            }
        )
    }
    
    func toggle(filter: Filter) -> Binding<Bool> {
        Binding(
            get: {
                self.filter == filter
            },
            set: { isOn in
                if isOn, self.filter != filter {
                    withAnimation(.snappy) {
                        self.filter = filter
                    }
                } else {
                    withAnimation(.snappy) {
                        self.filter = .all
                    }
                }
            }
        )
    }
}
