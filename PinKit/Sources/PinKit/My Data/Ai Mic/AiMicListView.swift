import SwiftUI
import SwiftData

struct AiMicQueryView: View {
    
    @Query(AiMicEvent.all())
    private var events: [AiMicEvent]
    
    init(descriptor: FetchDescriptor<AiMicEvent>) {
        self._events = .init(descriptor)
    }
    
    var body: some View {
        ForEach(events) { event in
            AiMicCellView(event: event)
        }
    }
}

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
    
    var query: String
    
    var predicate: Predicate<AiMicEvent> {
        if query.isEmpty {
            return #Predicate { _ in
                true
            }
        } else {
            return #Predicate { event in
                event.request.contains(query) || event.response.contains(query)
            }
        }
    }
    
    var body: some View {
        List {
            var descriptor = AiMicEvent.all()
            let _ = descriptor.predicate = predicate
            AiMicQueryView(descriptor: descriptor)
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
