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
