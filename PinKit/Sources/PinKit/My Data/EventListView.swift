import SwiftUI
import SwiftData

struct EventListView<A: PersistentModel, Content: View>: View {
    
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

    var intent: any SyncManager
    var descriptor: FetchDescriptor<A>
    var predicate: () -> Predicate<A>
    var content: (A) -> Content
    
    var body: some View {
        var descriptor = descriptor
        let _ = descriptor.predicate = predicate()
        QueryListView(descriptor: descriptor) { event in
            content(event)
        } placeholder: {
            ContentUnavailableView("No data yet", systemImage: "person.text.rectangle")
        }
        .environment(\.isLoading, isLoading)
        .environment(\.isFirstLoad, isFirstLoad)
        .overlay(alignment: .bottom) {
            SyncStatusView(
                current: intent.currentKeyPath,
                total: intent.totalKeyPath
            )
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
            var intent = intent
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

