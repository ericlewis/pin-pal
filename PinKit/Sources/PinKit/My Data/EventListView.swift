import SwiftUI
import SwiftData

struct EventListView<Model: PersistentModel, Intent: SyncManager, Content: View>: View {
    
    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(AppState.self)
    private var app

    @State
    private var isFirstLoad = true

    var intent: Intent
    var descriptor: FetchDescriptor<Model>
    var predicate: () -> Predicate<Model>
    var content: (Model) -> Content

    var body: some View {
        var descriptor = descriptor
        let _ = descriptor.predicate = predicate()
        QueryListView(descriptor: descriptor) { event in
            content(event)
        } placeholder: {
            ContentUnavailableView("No data yet", systemImage: "person.text.rectangle")
        }
        .environment(\.isLoading, app[keyPath: intent.isLoadingKeyPath])
        .environment(\.isFirstLoad, isFirstLoad)
        .overlay(alignment: .bottom) {
            SyncStatusView(
                current: intent.currentKeyPath,
                total: intent.totalKeyPath
            )
        }
        .refreshable(intent: intent)
        .task(intent: intent)
    }
}

