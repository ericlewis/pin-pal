import SwiftUI

struct MyDataView: View {

    @State
    private var query: String = ""
    
    @State
    private var selectedFilter = MyDataFilter.aiMic
    
    var body: some View {
        NavigationStack {
            Group {
                let query = query.lowercased()
                switch selectedFilter {
                case .aiMic:
                    AiMicListView(query: query)
                case .calls:
                    CallEventListView(query: query.lowercased())
                case .music:
                    MusicEventListView(query: query.lowercased())
                case .translations:
                    TranslationEventListView(query: query.lowercased())
                }
            }
            .searchable(text: $query)
            .navigationTitle(selectedFilter.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarTitleMenu {
                    ForEach(MyDataFilter.allCases.filter({ $0 != selectedFilter })) { filter in
                        Button(filter.title, systemImage: filter.systemImage) {
                            selectedFilter = filter
                        }
                    }
                }
            }
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
