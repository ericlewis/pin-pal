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
                        VStack {
                            if let vidUrl = capture.videoDownloadUrl() {
                                VideoView(id: capture.uuid, vidUrl: vidUrl)
                            } else {
                                WebImage(url: makeThumbnailURL(content: capture, capture: capture.get()!))
                                    .resizable()
                                    .scaledToFit()
                            }
                        }
                        .toolbar {
                            Menu("Options", systemImage: "ellipsis.circle") {
                                makeMenuContents(for: capture)
                            }
                        }
                        .navigationTitle("Capture")
                    } label: {
                        ContentCellView(content: capture)
                    }
                    .contextMenu {
                        makeMenuContents(for: capture)
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
            } else if !isSearching, query.isEmpty {
                await repository.reload()
            }
        }
    }
    
    @ViewBuilder
    func makeMenuContents(for capture: ContentEnvelope) -> some View {
        Section {
            Button("Copy", systemImage: "doc.on.doc") {
                Task {
                    await repository.copyToClipboard(capture: capture)
                }
            }
            Button("Save to Camera Roll", systemImage: "square.and.arrow.down") {
                Task {
                    await repository.save(capture: capture)
                }
            }
            Button(capture.favorite ? "Unfavorite" : "Favorite", systemImage: "heart") {
                Task {
                    await repository.toggleFavorite(content: capture)
                }
            }
            .symbolVariant(capture.favorite ? .slash : .none)
        }
        Section {
            Button("Delete", systemImage: "trash", role: .destructive) {
                Task {
                    await repository.remove(content: capture)
                }
            }
        }
    }
    
    func makeThumbnailURL(content: ContentEnvelope, capture: CaptureEnvelope) -> URL? {
        URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(content.uuid.uuidString)/file/\(capture.thumbnail.fileUUID)")?.appending(queryItems: [
            .init(name: "token", value: capture.thumbnail.accessToken),
            .init(name: "w", value: "640"),
            .init(name: "q", value: "100")
        ])
    }
}

