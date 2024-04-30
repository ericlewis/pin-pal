import SwiftUI

struct MyDataView: View {

    @Environment(MyDataRepository.self)
    private var repository

    var body: some View {
        NavigationStack {
            List {
                ForEach(repository.content[repository.selectedFilter] ?? []) { event in
                    let createdAt = event.eventCreationTime
                    switch event.eventData {
                    case let .aiMic(event):
                        AiMicCellView(event: event, createdAt: createdAt)
                    case let .music(event):
                        MusicCellView(event: event, createdAt: createdAt)
                    case let .call(event):
                        CallCellView(event: event, createdAt: createdAt)
                    case let .translation(event):
                        TranslationCellView(event: event, createdAt: createdAt)
                    case .unknown:
                        UnknownCellView()
                    }
                }
                .onDelete { indexSet in
                    Task {
                        await repository.remove(offsets: indexSet)
                    }
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
                        Button(filter.title, systemImage: filter.systemImage) {
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

