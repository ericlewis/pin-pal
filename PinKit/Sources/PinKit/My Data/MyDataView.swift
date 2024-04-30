import SwiftUI

struct MyDataView: View {

    @Environment(MyDataRepository.self)
    private var repository

    var body: some View {
        NavigationStack {
            List {
                ForEach(repository.content[repository.selectedFilter] ?? []) { event in
                    DataCellView(event: event)
                }
                if repository.hasMoreData {
                    HStack {
                        Spacer()
                        ProgressView()
                        Spacer()
                    }
                    .task {
                        await repository.loadMore()
                    }
                }
            }
            .refreshable(action: repository.reload)
            .searchable(text: .constant(""))
            .navigationTitle(repository.selectedFilter.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarTitleMenu {
                    ForEach(MyDataFilter.allCases.filter({ $0 != repository.selectedFilter })) { filter in
                        Button(filter.title) {
                            repository.selectedFilter = filter
                        }
                    }
                }
            }
        }
        .overlay {
            if !repository.hasContent, repository.isLoading {
                ProgressView()
            } else if !repository.hasContent, repository.isFinished {
                ContentUnavailableView("No data yet", systemImage: "person.text.rectangle")
            }
        }
        .task(repository.initial)
    }
}

#Preview {
    MyDataView()
        .environment(HumaneCenterService.live())
}

