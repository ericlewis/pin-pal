import SwiftUI

struct MyDataView: View {
    
    struct ViewState {
        var events: [EventContentEnvelope] = []
        var isLoading = false
        var selectedFilter: MyDataFilter = .aiMic
    }
    
    @State
    private var state = ViewState()
    
    @Environment(HumaneCenterService.self)
    private var api

    var body: some View {
        NavigationStack {
            List {
                ForEach(state.events, id: \.eventIdentifier) { event in
                    DataCellView(event: event)
                }
            }
            .refreshable {
                await load()
            }
            .searchable(text: .constant(""))
            .navigationTitle(state.selectedFilter.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarTitleMenu {
                    ForEach(MyDataFilter.allCases.filter({ $0 != state.selectedFilter })) { filter in
                        Button(filter.title) {
                            state.selectedFilter = filter
                        }
                    }
                }
            }
        }
        .overlay {
            if !state.isLoading, state.events.isEmpty {
                ContentUnavailableView("No data yet", systemImage: "person.text.rectangle")
            } else if state.isLoading, state.events.isEmpty {
                ProgressView()
            }
        }
        .task(id: state.selectedFilter) {
            state.isLoading = true
            withAnimation {
                state.events = []
            }
            while !Task.isCancelled {
                await load()
                state.isLoading = false
                try? await Task.sleep(for: .seconds(15))
            }
        }
    }
    
    func load() async {
        do {
            let events = try await api.events(state.selectedFilter.domain, 20)
            withAnimation {
                self.state.events = events.content
            }
        } catch {
            print(error)
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

#Preview {
    MyDataView()
        .environment(HumaneCenterService.live())
}

