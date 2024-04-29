import SwiftUI
import SDWebImageSwiftUI
import UniformTypeIdentifiers
import AVKit

extension URL {
    static func videoDownloadUrl(uuid: UUID, fileUUID: UUID, accessToken: String) -> URL? {
        return URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(uuid)/file/\(fileUUID)/download")?.appending(queryItems: [
            URLQueryItem(name: "token", value: accessToken),
            URLQueryItem(name: "rawData", value: "false")
        ])
    }
}

extension ContentEnvelope {
    func videoDownloadUrl() -> URL? {
        guard let cap: CaptureEnvelope = self.get(), let vid = cap.video else {
            return nil
        }
        return URL.videoDownloadUrl(uuid: uuid, fileUUID: vid.fileUUID, accessToken: vid.accessToken)
    }
}

struct VideoView: View {
    
    let id: UUID
    let vidUrl: URL
    let accessToken: String
    
    @State
    private var player = AVPlayer()
    
    var body: some View {
        VideoPlayer(player: player)
            .aspectRatio(960 / 720, contentMode: .fit)
            .task {
                let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let targetURL = tempDirectoryURL.appendingPathComponent(id.uuidString).appendingPathExtension("mp4")
                do {
                    if try FileManager.default.fileExists(atPath: targetURL.path()) {
                        player.replaceCurrentItem(with: .init(url: targetURL))
                    } else {
                        var req = URLRequest(url: vidUrl)
                        req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
                        let (data, _) = try await URLSession.shared.data(for: req)
                        try FileManager.default.createFile(atPath: targetURL.path(), contents: data)
                        player.replaceCurrentItem(with: .init(url: targetURL))
                    }
                    await player.seek(to: .zero)
                    player.isMuted = true
                    player.play()
                } catch let error {
                    print("Unable to copy file: \(error)")
                }
            }
            .onDisappear {
                player.pause()
            }
            .background {
                Color.black
            }
    }
}

struct CapturesView: View {
    
    struct ViewState {
        var isLoading = false
        var captures: [ContentEnvelope] = []
    }
    
    @State
    private var state = ViewState()
    
    @Environment(HumaneCenterService.self)
    private var api
    
    @AppStorage(Constant.ACCESS_TOKEN)
    private var accessToken: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [.init(.adaptive(minimum: 100, maximum: 300), spacing: 2)], spacing: 2) {
                    ForEach(state.captures, id: \.uuid) { capture in
                        NavigationLink {
                            VStack {
                                if let vidUrl = capture.videoDownloadUrl(), let accessToken {
                                    VideoView(id: capture.uuid, vidUrl: vidUrl, accessToken: accessToken)
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
                    Task {
                        do {
                            try await api.unfavorite(capture)
                        } catch {
                            print(error)
                        }
                    }
                }
                .symbolVariant(.slash)
            } else {
                Button("Favorite", systemImage: "heart") {
                    Task {
                        do {
                            try await api.favorite(capture)
                        } catch {
                            print(error)
                        }
                    }
                }
            }
        }
        Section {
            Button("Delete", systemImage: "trash", role: .destructive) {
                
            }
        }
    }
    
    func save(capture: ContentEnvelope) async throws {
        if capture.get()?.video == nil {
            try await UIImageWriteToSavedPhotosAlbum(image(for: capture), nil, nil, nil)
        } else {
            try await saveVideo(capture: capture)
        }
    }
    
    func saveVideo(capture: ContentEnvelope) async throws {
        guard let url = capture.videoDownloadUrl() else { return }
        let tempDirectoryURL = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
        let targetURL = tempDirectoryURL.appendingPathComponent(capture.uuid.uuidString).appendingPathExtension("mp4")
        if try FileManager.default.fileExists(atPath: targetURL.path()) {
            UISaveVideoAtPathToSavedPhotosAlbum(targetURL.path(), nil, nil, nil)
        } else {
            var req = URLRequest(url: url)
            req.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            let (data, _) = try await URLSession.shared.data(for: req)
            try FileManager.default.createFile(atPath: targetURL.path(), contents: data)
            UISaveVideoAtPathToSavedPhotosAlbum(targetURL.path(), nil, nil, nil)
        }
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
    
    func makeThumbnailURL(content: ContentEnvelope, capture: CaptureEnvelope) -> URL? {
        URL(string: "https://webapi.prod.humane.cloud/capture/memory/\(content.uuid.uuidString)/file/\(capture.thumbnail.fileUUID)")?.appending(queryItems: [
            .init(name: "token", value: capture.thumbnail.accessToken),
            .init(name: "w", value: "640"),
            .init(name: "q", value: "100")
        ])
    }
}

#Preview {
    CapturesView()
        .environment(HumaneCenterService.live())
}
