import SwiftUI
import OSLog

@Observable public class MyDataRepository {
    let logger = Logger()
    var api: HumaneCenterService
    var data: PageableEventContentEnvelope?
    var content: [MyDataFilter: [EventContentEnvelope]] = [:]
    var isLoading: Bool = false
    var isFinished: Bool = false
    var hasMoreData: Bool = false
    
    var selectedFilter = MyDataFilter.aiMic {
        didSet {
            Task {
                await reload()
            }
        }
    }
    
    var hasContent: Bool {
        guard let content = content[selectedFilter] else {
            return false
        }
        return !content.isEmpty
    }
    
    public init(api: HumaneCenterService = .live()) {
        self.api = api
    }
}

extension MyDataRepository {
    private func load(page: Int = 0, size: Int = 10, reload: Bool = false) async {
        isLoading = true
        do {
            let data = try await api.events(selectedFilter.domain, page, size)
            self.data = data
            withAnimation {
                if reload {
                    self.content[selectedFilter] = data.content
                } else {
                    if self.content[self.selectedFilter] == nil {
                        self.content[self.selectedFilter] = []
                    }
                    self.content[self.selectedFilter]?.append(contentsOf: data.content)
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
                let event = withAnimation {
                    content[selectedFilter]?.remove(at: i)
                }
                guard let event else { return }
                try await api.deleteEvent(event)
            }
        } catch {
            logger.debug("\(error)")
        }
    }
}

enum MyDataFilter {
    case aiMic
    case calls
    case music
    case translations
    
    var title: LocalizedStringKey {
        switch self {
        case .aiMic:
            "Ai Mic"
        case .calls:
            "Calls"
        case .music:
            "Music"
        case .translations:
            "Translation"
        }
    }
    
    var systemImage: String {
        switch self {
        case .aiMic:
            "mic"
        case .calls:
            "phone"
        case .music:
            "music.note"
        case .translations:
            "bubble.left.and.text.bubble.right"
        }
    }
    
    var domain: EventDomain {
        switch self {
        case .aiMic: .aiMic
        case .calls: .calls
        case .music: .music
        case .translations: .translation
        }
    }
}

extension MyDataFilter: CaseIterable {}

extension MyDataFilter: Identifiable {
    var id: Self { self }
}
