import SwiftUI
import SDWebImageSwiftUI

struct CapturesView: View {
    
    struct ViewState {
        var isLoading = false
        var captures: [ContentEnvelope] = []
    }
    
    @State
    private var state = ViewState()
    
    @Environment(HumaneCenterService.self)
    private var api
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [.init(.adaptive(minimum: 100, maximum: 300), spacing: 1)], spacing: 1) {
                    ForEach(state.captures, id: \.uuid) { capture in
                        NavigationLink {
                            WebImage(url: makeThumbnailURL(content: capture, capture: capture.get()!))
                                .resizable()
                                .scaledToFit()
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
                }
            }
            .searchable(text: .constant(""))
            .refreshable {
                await load()
            }
            .listSectionSpacing(15)
            .navigationTitle("Captures")
        }
        .overlay {
            if !state.isLoading, state.captures.isEmpty {
                ContentUnavailableView("No captures yet", systemImage: "camera.aperture")
            } else if state.isLoading, state.captures.isEmpty {
                ProgressView()
            }
        }
        .task {
            state.isLoading = true
            while !Task.isCancelled {
                await load()
                state.isLoading = false
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }
    
    func load() async {
        do {
            let captures = try await api.captures(100)
            withAnimation {
                state.captures = captures.content
            }
        } catch {
            print(error)
        }
    }
    
    func makeThumbnailURL(content: ContentEnvelope, capture: CaptureEnvelope) -> URL? {
        URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(content.uuid.uuidString)/file/\(capture.thumbnail.fileUUID)")?.appending(queryItems: [
            .init(name: "token", value: capture.thumbnail.accessToken),
            .init(name: "w", value: "640"),
            .init(name: "q", value: "100")
        ])
    }

    @ViewBuilder
    func makeMenuContents(for capture: ContentEnvelope) -> some View {
        Section {
            Button("Copy", systemImage: "doc.on.doc") {
                Task {
                    try await UIPasteboard.general.image = image(for: capture)
                }
            }
            Button("Save to Camera Roll", systemImage: "square.and.arrow.down") {
                Task {
                    try await save(capture: capture)
                }
            }
            if capture.favorite {
                Button("Unfavorite", systemImage: "heart") {
                    // TODO:
                }
                .symbolVariant(.slash)
            } else {
                Button("Favorite", systemImage: "heart") {
                    // TODO:
                }
            }
        }
        Section {
            Button("Delete", systemImage: "trash", role: .destructive) {
                
            }
        }
    }

    func save(capture: ContentEnvelope) async throws {
        try await UIImageWriteToSavedPhotosAlbum(image(for: capture), nil, nil, nil)
    }

    func image(for capture: ContentEnvelope) async throws -> UIImage {
        guard let cap: CaptureEnvelope = capture.get() else { return UIImage() }
        let (data, _) = try await URLSession.shared.data(from: URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(capture.uuid)/file/\(cap.thumbnail.fileUUID)")!.appending(queryItems: [
            .init(name: "token", value: cap.thumbnail.accessToken),
            .init(name: "w", value: "640"),
            .init(name: "q", value: "100")
        ]))
        guard let image = UIImage(data: data) else {
            fatalError()
        }
        return image
        UIImage()
    }
}

#Preview {
    CapturesView()
        .environment(HumaneCenterService.live())
}
