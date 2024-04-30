import SwiftUI

struct MyDataView: View {
    
    @Environment(MyDataRepository.self)
    private var repository
    
    @State
    private var query: String = ""
    
    var body: some View {
        NavigationStack {
            SearchableMyDataListView(query: $query)
                .refreshable(action: repository.reload)
                .searchable(text: $query)
                .navigationTitle(repository.selectedFilter.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        EditButton()
                    }
                    ToolbarTitleMenu {
                        ForEach(MyDataFilter.allCases.filter({ $0 != repository.selectedFilter })) { filter in
                            Button(filter.title, systemImage: filter.systemImage) {
                                repository.selectedFilter = filter
                            }
                        }
                    }
                }
        }
        .task(repository.initial)
    }
}

#Preview {
    MyDataView()
        .environment(HumaneCenterService.live())
}

