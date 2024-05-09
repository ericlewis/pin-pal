import SwiftUI

struct MyDataView: View {
    
    @Environment(MyDataRepository.self)
    private var repository
    
    @State
    private var query: String = ""
    
    var body: some View {
        NavigationStack {
            Group {
                if repository.selectedFilter == .aiMic {
                    AiMicListView(query: query.lowercased())
                } else if repository.selectedFilter == .calls {
                    CallEventListView(query: query.lowercased())
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

