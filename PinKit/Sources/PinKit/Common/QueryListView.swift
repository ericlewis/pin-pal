import SwiftUI
import SwiftData

struct LoadingEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

extension EnvironmentValues {
    var isLoading: Bool {
        get { self[LoadingEnvironmentKey.self] }
        set { self[LoadingEnvironmentKey.self] = newValue }
    }
}

struct FirstLoadEnvironmentKey: EnvironmentKey {
    static let defaultValue: Bool = true
}

extension EnvironmentValues {
    var isFirstLoad: Bool {
        get { self[FirstLoadEnvironmentKey.self] }
        set { self[FirstLoadEnvironmentKey.self] = newValue }
    }
}

struct QueryListView<Model: PersistentModel, Content: View, Placeholder: View>: View {
    
    @Environment(\.isSearching)
    private var isSearching
    
    @Environment(\.isLoading)
    private var isLoading
    
    @Environment(\.isFirstLoad)
    private var isFirstLoad
    
    @Query
    private var data: [Model]

    let content: (Model) -> Content
    let placeholder: () -> Placeholder

    init(descriptor: FetchDescriptor<Model>, content: @escaping (Model) -> Content, placeholder: @escaping () -> Placeholder) {
        self._data = .init(descriptor)
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        List {
            ForEach(data) { datum in
                content(datum)
            }
        }
        .overlay {
            if isSearching, data.isEmpty, !isLoading {
                ContentUnavailableView.search
            } else if data.isEmpty, isLoading {
                ProgressView()
            } else if data.isEmpty, !isSearching, !isFirstLoad {
                placeholder()
            }
        }
    }
}

struct QueryGridView<Model: PersistentModel, Content: View, Placeholder: View>: View {
    
    @Environment(\.isSearching)
    private var isSearching
    
    @Environment(\.isLoading)
    private var isLoading
    
    @Environment(\.isFirstLoad)
    private var isFirstLoad
    
    @Query
    private var data: [Model]

    let content: (Model) -> Content
    let placeholder: () -> Placeholder

    init(descriptor: FetchDescriptor<Model>, content: @escaping (Model) -> Content, placeholder: @escaping () -> Placeholder) {
        self._data = .init(descriptor)
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(.adaptive(minimum: 100, maximum: 300), spacing: 2)], spacing: 2) {
                ForEach(data) { datum in
                    content(datum)
                }
            }
        }
        .overlay {
            if isSearching, data.isEmpty, !isLoading {
                ContentUnavailableView.search
            } else if data.isEmpty, isLoading {
                ProgressView()
            } else if data.isEmpty, !isSearching, !isFirstLoad {
                placeholder()
            }
        }
    }
}
