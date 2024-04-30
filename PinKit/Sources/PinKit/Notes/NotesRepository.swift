import SwiftUI
import OSLog
import CollectionConcurrencyKit

@Observable public class NotesRepository {
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

extension NotesRepository {
    private func load(page: Int = 0, size: Int = 10, reload: Bool = false) async {
        isLoading = true
        do {
            let data = try await api.notes(page, size)
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
    
    public func remove(offsets: IndexSet) async {
        do {
            for i in offsets {
                let note = withAnimation {
                    content.remove(at: i)
                }
                try await api.delete(note)
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
            
        }
    }
    
    public func create(note: Note) async {
        do {
            let note = try await api.create(note)
            withAnimation {
                content.insert(note, at: 0)
            }
        } catch {
            logger.debug("\(error)")
        }
    }
    
    public func update(note: Note) async {
        do {
            let note = try await api.update(note.memoryId!.uuidString, .init(text: note.text, title: note.title))
            guard let idx = self.content.firstIndex(where: { $0.uuid == note.uuid }) else {
                return
            }
            withAnimation {
                self.content[idx] = note
            }
        } catch {
            logger.debug("\(error)")
        }
    }
    
    public func search(query: String) async {
        isLoading = true
        do {
            try await Task.sleep(for: .milliseconds(300))
            guard let searchIds = try await api.search(query, .notes).memories?.map(\.uuid) else {
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
}
