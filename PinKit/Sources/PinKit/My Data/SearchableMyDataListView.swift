import SwiftUI

struct SearchableMyDataListView: View {
    
    @Environment(MyDataRepository.self)
    private var repository
    
    @Environment(\.isSearching)
    private var isSearching
    
    @Binding
    var query: String
    
    var searchContent: [EventContentEnvelope] {
        (repository.content[repository.selectedFilter] ?? []).filter({ item in
            if query.isEmpty {
                return true
            }
            let query = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            switch item.eventData {
            case let .aiMic(event):
                return event.request.lowercased().contains(query) || event.response.lowercased().contains(query)
            case let .call(event):
                return event.peers.contains {
                    $0.displayName.lowercased().contains(query) || $0.phoneNumber.lowercased().contains(query)
                }
            case let .music(event):
                if let prompt = event.prompt?.lowercased().contains(query) {
                    return prompt
                }
                return (event.artistName?.lowercased().contains(query) ?? false)
                || (event.trackTitle?.lowercased().contains(query) ?? false)
                || (event.albumName?.lowercased().contains(query) ?? false)
            case let .translation(event):
                return event.targetLanguage.lowercased().contains(query) || event.originLanguage.lowercased().contains(query)
            case .unknown:
                return false
            }
        })
    }
    
    var body: some View {
        List {
            ForEach(isSearching ? searchContent : repository.content[repository.selectedFilter] ?? []) { event in
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
            if !isSearching, repository.hasMoreData {
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
        .overlay {
            if isSearching, !repository.isLoading, searchContent.isEmpty {
                ContentUnavailableView.search
            } else if !repository.hasContent, repository.isLoading {
                ProgressView()
            } else if !repository.hasContent, !isSearching, repository.isFinished {
                ContentUnavailableView("No data yet", systemImage: "person.text.rectangle")
            }
        }
    }
}
