import SwiftUI
import SwiftData

struct AiMicListView: View {
    
    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(AppState.self)
    private var app
    
    @Environment(\.isSearching)
    private var isSearching
    
    @State
    private var isLoading = false
    
    @State
    private var isFirstLoad = true
    
    @Query(AiMicEvent.all())
    private var events: [AiMicEvent]
    
    var body: some View {
        List {
            ForEach(events) { event in
                AiMicCellView(event: event)
            }
        }
        .overlay {
            if isSearching, events.isEmpty, !isLoading {
                ContentUnavailableView.search
            } else if events.isEmpty, isLoading {
                ProgressView()
            } else if events.isEmpty, !isSearching, !isFirstLoad {
                ContentUnavailableView("No data yet", systemImage: "person.text.rectangle")
            }
        }
        .overlay(alignment: .bottom) {
            if app.totalAiMicEventsToSync > 0, app.numberOfAiMicEventsSynced > 0 {
                let current = Double(app.numberOfAiMicEventsSynced)
                let total = Double(app.totalAiMicEventsToSync)
                ProgressView(value:  current / total)
                    .padding(.horizontal, -5)
            }
        }
        .refreshable(action: load)
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
            let intent = SyncAiMicIntent()
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

struct MyDataView: View {
    
    @Environment(MyDataRepository.self)
    private var repository
    
    @State
    private var query: String = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if repository.selectedFilter == .aiMic {
                    AiMicListView()
                } else {
                    SearchableMyDataListView(query: $query)
                        .task(repository.initial)
                }
            }
            .refreshable(action: repository.reload)
            .searchable(text: $query)
            .navigationTitle(repository.selectedFilter.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarTitleMenu {
                    ForEach(MyDataFilter.allCases.filter({ $0 != repository.selectedFilter })) { filter in
                        Button(filter.title, systemImage: filter.systemImage) {
                            repository.selectedFilter = filter
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    MyDataView()
        .environment(HumaneCenterService.live())
}

