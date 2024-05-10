import SwiftUI
import SwiftData

struct MusicEventListView: View {
    
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
    
    var predicate: Predicate<MusicEvent> {
        if query.isEmpty {
            return #Predicate { _ in
                true
            }
        } else {
            return #Predicate { event in
                return event.artistName?.contains(query) == true || event.albumName?.contains(query) == true
            }
        }
    }
    
    var body: some View {
        var descriptor = MusicEvent.all()
        let _ = descriptor.predicate = predicate
        QueryListView(descriptor: descriptor) { event in
            MusicCellView(event: event)
        } placeholder: {
            ContentUnavailableView("No data yet", systemImage: "person.text.rectangle")
        }
        .environment(\.isLoading, isLoading)
        .environment(\.isFirstLoad, isFirstLoad)
        .overlay(alignment: .bottom) {
            MusicEventSyncStatusView()
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
            let intent = SyncMusicEventsIntent()
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

struct MusicEventSyncStatusView: View {
    
    @Environment(AppState.self)
    private var app
        
    var body: some View {
        if app.totalMusicEventsToSync > 0, app.numberOfMusicEventsSynced > 0 {
            let current = Double(app.numberOfMusicEventsSynced)
            let total = Double(app.totalMusicEventsToSync)
            ProgressView(value:  current / total)
                .padding(.horizontal, -5)
        }
    }
}
