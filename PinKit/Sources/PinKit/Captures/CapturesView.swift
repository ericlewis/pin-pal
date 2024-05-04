import SwiftUI
import SwiftData

struct CapturesView: View {
    
    @State
    private var isLoading = false
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(NavigationStore.self)
    private var navigationStore

    @Environment(\.database)
    private var database
    
    @State
    private var searchResults: [UUID]?
    
    @State
    private var searchQuery = ""
    
    var body: some View {
        @Bindable var navigationStore = navigationStore
        NavigationStack {
            CapturesScrollGrid(uuids: searchResults, order: .reverse, isLoading: isLoading)
                .searchable(text: $searchQuery)
                .navigationTitle("Captures", displayMode: .inline)
        }
        .task(id: searchQuery, search)
    }
    
    private func search() async {
        do {
            try await Task.sleep(for: .milliseconds(300))
            guard !searchQuery.isEmpty else {
                withAnimation {
                    self.searchResults = nil
                }
                return
            }
            let res = try await service.search(searchQuery, .captures).memories ?? []
            searchResults = res.map(\.uuid)
        } catch is CancellationError {
            // noop
        } catch {
            let err = error as NSError
            if err.domain != NSURLErrorDomain, err.code != NSURLErrorCancelled {
                print(error)
            }
        }
    }
}
