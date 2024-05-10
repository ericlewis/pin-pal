import SwiftUI
import SwiftData

struct TranslationEventListView: View {
    
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
    
    var predicate: Predicate<TranslationEvent> {
        if query.isEmpty {
            return #Predicate { _ in
                true
            }
        } else {
            return #Predicate { event in
                return event.originLanguage.contains(query) || event.targetLanguage.contains(query)
            }
        }
    }
    
    var body: some View {
        var descriptor = TranslationEvent.all()
        let _ = descriptor.predicate = predicate
        QueryListView(descriptor: descriptor) { event in
            TranslationCellView(event: event)
        } placeholder: {
            ContentUnavailableView("No data yet", systemImage: "person.text.rectangle")
        }
        .environment(\.isLoading, isLoading)
        .environment(\.isFirstLoad, isFirstLoad)
        .overlay(alignment: .bottom) {
            TranslationEventSyncStatusView()
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
            let intent = SyncTranslationEventsIntent()
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

struct TranslationEventSyncStatusView: View {
    
    @Environment(AppState.self)
    private var app
        
    var body: some View {
        if app.totalCallEventsToSync > 0, app.numberOfCallEventsSynced > 0 {
            let current = Double(app.numberOfCallEventsSynced)
            let total = Double(app.totalCallEventsToSync)
            ProgressView(value:  current / total)
                .padding(.horizontal, -5)
        }
    }
}
