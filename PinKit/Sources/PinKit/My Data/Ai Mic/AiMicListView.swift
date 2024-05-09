import SwiftUI
import SwiftData

struct AiMicListView: View {
    
    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(AppState.self)
    private var app

    @State
    private var isLoading = false
    
    @State
    private var isFirstLoad = true

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
        var descriptor = AiMicEvent.all()
        let _ = descriptor.predicate = predicate
        QueryListView(descriptor: descriptor) { event in
            AiMicCellView(event: event)
        } placeholder: {
            ContentUnavailableView("No data yet", systemImage: "person.text.rectangle")
        }
        .environment(\.isLoading, isLoading)
        .environment(\.isFirstLoad, isFirstLoad)
        .overlay(alignment: .bottom) {
            AiMicSyncStatusView()
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

struct AiMicSyncStatusView: View {
    
    @Environment(AppState.self)
    private var app
    
    var body: some View {
        if app.totalAiMicEventsToSync > 0, app.numberOfAiMicEventsSynced > 0 {
            let current = Double(app.numberOfAiMicEventsSynced)
            let total = Double(app.totalAiMicEventsToSync)
            ProgressView(value:  current / total)
                .padding(.horizontal, -5)
        }
    }
}
