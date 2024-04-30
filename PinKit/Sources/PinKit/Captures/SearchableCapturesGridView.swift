import SwiftUI
import SDWebImageSwiftUI

struct SearchableCapturesGridView: View {
    
    @Environment(CapturesRepository.self)
    private var repository
    
    @Environment(\.isSearching)
    private var isSearching
    
    @Binding
    var query: String
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [.init(.adaptive(minimum: 100, maximum: 300), spacing: 2)], spacing: 2) {
                ForEach(repository.content) { capture in
                    NavigationLink {
                        CaptureDetailView(capture: capture)
                    } label: {
                        ContentCellView(content: capture)
                    }
                    .contextMenu {
                        CaptureMenuContents(capture: capture)
                    }
                }
                if !isSearching, repository.hasMoreData {
                    Rectangle()
                        .fill(.bar)
                        .aspectRatio(1, contentMode: .fit)
                        .overlay(ProgressView())
                        .task {
                            await repository.loadMore()
                        }
                }
            }
        }
        .overlay {
            if isSearching, !repository.isLoading, !repository.hasContent {
                ContentUnavailableView.search
            } else if !repository.hasContent, repository.isLoading {
                ProgressView()
            } else if !repository.hasContent, !isSearching, repository.isFinished {
                ContentUnavailableView("No captures yet", systemImage: "camera.aperture")
            }
        }
        .task(id: query + (isSearching ? "true" : "false")) {
            if isSearching, !query.isEmpty {
                await repository.search(query: query)
            } else if query.isEmpty {
                await repository.reload()
            }
        }
    }
}

