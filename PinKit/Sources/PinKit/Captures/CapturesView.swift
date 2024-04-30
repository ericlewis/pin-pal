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
    
    @AppStorage(Constant.ACCESS_TOKEN)
    private var accessToken: String?
    
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
                        req.setValue("Bearer \(accessToken!)", forHTTPHeaderField: "Authorization")
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

    @Environment(CapturesRepository.self)
    private var capturesRepository
    
    @Environment(NavigationStore.self)
    private var navigationStore

    var body: some View {
        @Bindable var navigationStore = navigationStore
        NavigationStack(path: $navigationStore.capturesNavigationPath) {
            ScrollView {
                LazyVGrid(columns: [.init(.adaptive(minimum: 100, maximum: 300), spacing: 2)], spacing: 2) {
                    ForEach(capturesRepository.content) { capture in
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
                    if capturesRepository.hasMoreData {
                        Rectangle()
                            .fill(.bar)
                            .overlay(ProgressView())
                            .task {
                                await capturesRepository.loadMore()
                            }
                    }
                }
            }
            .refreshable(action: capturesRepository.reload)
            .searchable(text: .constant(""))
            .listSectionSpacing(15)
            .navigationTitle("Captures")
        }
        .overlay {
            if !capturesRepository.hasContent, capturesRepository.isLoading {
                ProgressView()
            } else if !capturesRepository.hasContent, capturesRepository.isFinished {
                ContentUnavailableView("No captures yet", systemImage: "camera.aperture")
            }
        }
        .task(capturesRepository.initial)
    }

    @ViewBuilder
    func makeMenuContents(for capture: ContentEnvelope) -> some View {
        Section {
            Button("Copy", systemImage: "doc.on.doc") {
                Task {
                    await capturesRepository.copyToClipboard(capture: capture)
                }
            }
            Button("Save to Camera Roll", systemImage: "square.and.arrow.down") {
                Task {
                    await capturesRepository.save(capture: capture)
                }
            }
            Button(capture.favorite ? "Unfavorite" : "Favorite", systemImage: "heart") {
                Task {
                    await capturesRepository.toggleFavorite(content: capture)
                }
            }
            .symbolVariant(capture.favorite ? .slash : .none)
        }
        Section {
            Button("Delete", systemImage: "trash", role: .destructive) {
                Task {
                    await capturesRepository.remove(content: capture)
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

#Preview {
    CapturesView()
        .environment(HumaneCenterService.live())
}
