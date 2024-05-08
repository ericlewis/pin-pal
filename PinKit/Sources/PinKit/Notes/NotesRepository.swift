import SwiftUI
import OSLog
import CollectionConcurrencyKit
import OrderedCollections

@Observable public final class NotesRepository: Sendable {
    let logger = Logger()
    var api: HumaneCenterService
    var database: any Database
    var data: PageableMemoryContentEnvelope?
    var contentSet: OrderedSet<ContentEnvelope> = []
    public var content: [ContentEnvelope] = []
    var isLoading: Bool = false
    var isFinished: Bool = false
    var hasMoreData: Bool = false
    var hasContent: Bool {
        !content.isEmpty
    }
    
    public init(api: HumaneCenterService = .live(), database: any Database) {
        self.api = api
        self.database = database
    }
}

extension NotesRepository {
    private func load(page: Int = 0, size: Int = 15, reload: Bool = false) async {
        guard !isLoading else { return }
        isLoading = true
        do {
            let data = try await api.notes(page, size)
            self.data = data
            self.hasMoreData = (data.totalPages - 1) != page
            try await data.content.concurrentForEach { content in
                do {
                    guard let note: Note = content.get() else {
                        return
                    }
                    try await self.database.insert(_Note(
                        uuid: note.uuid ?? .init(),
                        parentUUID: content.id,
                        name: note.title,
                        body: note.text,
                        isFavorite: content.favorite,
                        createdAt: content.userCreatedAt,
                        modifedAt: content.userLastModified)
                    )
                } catch {
                    print(error)
                }
            }
            try await self.database.save()
        } catch {
            print(error)
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
                    let _ = contentSet.remove(at: i)
                    return content.remove(at: i)
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
    
    // TODO: the main app intents are using these
    public func create(note: Note) async {
        
    }
    
    // TODO: the main app intents are using these
    public func update(note: Note) async {
        
    }
    
    public func search(query: String) async {
        isLoading = true
        do {
            try await Task.sleep(for: .milliseconds(300))
            guard let searchIds = try await api.search(query.trimmingCharacters(in: .whitespacesAndNewlines), .notes).memories?.map(\.uuid) else {
                self.contentSet.removeAll(keepingCapacity: true)
                self.content = []
                throw CancellationError()
            }
            var fetchedResults: [ContentEnvelope] = await try searchIds.concurrentCompactMap { id in
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
                self.contentSet = OrderedSet(fetchedResults)
                self.content = self.contentSet.elements
            }
        } catch is CancellationError {
            // noop
        } catch {
            logger.debug("\(error)")
        }
        isLoading = false
    }
}
