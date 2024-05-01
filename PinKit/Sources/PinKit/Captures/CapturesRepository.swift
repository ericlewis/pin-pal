import SwiftUI
import OSLog

@Observable public class CapturesRepository {
    let logger = Logger()
    var api: HumaneCenterService
    var data: PageableMemoryContentEnvelope?
    var content: [ContentEnvelope] = []
    var isLoading: Bool = false
    var isFinished: Bool = false
    var hasMoreData: Bool = false
    var hasContent: Bool {
        !content.isEmpty
    }
    
    public init(api: HumaneCenterService = .live()) {
        self.api = api
    }
}

extension CapturesRepository {
    private func load(page: Int = 0, size: Int = 18, reload: Bool = false) async {
        isLoading = true
        do {
            let data = try await api.captures(page, size)
            self.data = data
            withAnimation {
                if reload {
                    self.content = data.content
                } else {
                    self.content.append(contentsOf: data.content)
                }
            }
            self.hasMoreData = (data.totalPages - 1) != page
        } catch {
            logger.debug("\(error)")
        }
        isFinished = true
        isLoading = false
    }
    
    public func initial() async {
        guard !isFinished else { return }
        await load()
    }
    
    public func reload() async {
        await load(reload: true)
    }
    
    public func loadMore() async {
        guard let data, hasMoreData, !isLoading else {
            return
        }
        let nextPage = min(data.pageable.pageNumber + 1, data.totalPages)
        logger.debug("next page: \(nextPage)")
        await load(page: nextPage)
    }
    
    public func remove(content: ContentEnvelope) async {
        do {
            guard let i = self.content.firstIndex(where: { $0.uuid == content.uuid }) else {
                return
            }
            let capture = withAnimation {
                self.content.remove(at: i)
            }
            try await api.delete(capture)
        } catch {
            logger.debug("\(error)")
        }
    }
    
    public func remove(offsets: IndexSet) async {
        do {
            for i in offsets {
                let capture = withAnimation {
                    content.remove(at: i)
                }
                try await api.delete(capture)
            }
        } catch {
            logger.debug("\(error)")
        }
    }
    
    public func toggleFavorite(content: ContentEnvelope) async {
        do {
            if content.favorite {
                try await api.unfavorite(content)
            } else {
                try await api.favorite(content)
            }
            guard let idx = self.content.firstIndex(where: { $0.uuid == content.uuid }) else {
                return
            }
            self.content[idx].favorite = !content.favorite
        } catch {
            logger.debug("\(error)")
        }
    }
    
    public func copyToClipboard(capture: ContentEnvelope) async {
        UIPasteboard.general.image = try? await image(for: capture)
    }
    
    public func save(capture: ContentEnvelope) async {
        do {
            if capture.get()?.video == nil {
                try await UIImageWriteToSavedPhotosAlbum(image(for: capture), nil, nil, nil)
            } else {
                try await saveVideo(capture: capture)
            }
        } catch {
            logger.debug("\(error)")
        }
    }
    
    public func search(query: String) async {
        isLoading = true
        do {
            try await Task.sleep(for: .milliseconds(300))
            guard let searchIds = try await api.search(query.trimmingCharacters(in: .whitespacesAndNewlines), .captures).memories?.map(\.uuid) else {
                self.content = []
                throw CancellationError()
            }
            var fetchedResults: [ContentEnvelope] = await try searchIds.asyncCompactMap { id in
                if let localContent = self.content.first(where: { $0.uuid == id }) {
                    return localContent
                } else {
                    try Task.checkCancellation()
                    do {
                        return try await api.memory(id)
                    } catch {
                        logger.debug("\(error)")
                        return nil
                    }
                }
            }
            withAnimation {
                self.content = fetchedResults
            }
        } catch is CancellationError {
            // noop
        } catch {
            logger.debug("\(error)")
        }
        isLoading = false
    }
    
    func saveVideo(capture: ContentEnvelope) async throws {
        guard let url = capture.videoDownloadUrl(), let accessToken = UserDefaults.standard.string(forKey: Constants.ACCESS_TOKEN) else { return }
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
}
