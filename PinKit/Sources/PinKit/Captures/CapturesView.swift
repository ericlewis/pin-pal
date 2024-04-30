import SwiftUI

struct CapturesView: View {
    
    @Environment(CapturesRepository.self)
    private var repository
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @State
    private var query = ""
    
    var body: some View {
        @Bindable var navigationStore = navigationStore
        NavigationStack(path: $navigationStore.capturesNavigationPath) {
            SearchableCapturesGridView(query: $query)
                .refreshable(action: repository.reload)
                .searchable(text: $query)
                .listSectionSpacing(15)
                .navigationTitle("Captures")
        }
        .task(repository.initial)
    }
}

#Preview {
    CapturesView()
        .environment(HumaneCenterService.live())
}
