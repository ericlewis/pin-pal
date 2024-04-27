import SwiftUI

struct MyDataView: View {
    
    struct ViewState {
        var events: [EventContent] = []
        var isLoading = false
        var selectedFilter: MyDataFilter = .aiMic
    }
    
    @State
    private var state = ViewState()
    
    @EnvironmentObject private var colorStore: ColorStore
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(state.events, id: \.eventIdentifier) { event in
                    VStack(alignment: .leading) {
                        if let request = event.eventData["request"]?.value as? String, let response = event.eventData["response"]?.value as? String {
                            Text(request)
                                .font(.headline)
                                .foregroundStyle(colorStore.accentColor)
                                .padding([.bottom], 5)
                            Text(response)
                        }
                        if let targetLanguage = event.eventData["targetLanguage"]?.value as? String, let originLanguage = event.eventData["originLanguage"]?.value as? String {
                            HStack {
                                Text(originLanguage)
                                    .foregroundStyle(colorStore.accentColor)
                                Spacer()
                                Text(targetLanguage)
                                    .foregroundStyle(colorStore.accentColor)
                            }
                            .overlay {
                                Image(systemName: "arrow.forward")
                            }
                        }
                        if let p = event.eventData["prompt"]?.value as? String, let music = event.eventData["generatedPlaylist"]?.value as? String {
                            Text(p)
                                .font(.headline)
                                .foregroundStyle(colorStore.accentColor)
                                .padding([.bottom], 5)
                            Text(music)
                        }
                        Text(event.eventCreationTime, format: .dateTime)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding([.top], 10)
                    }
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
            let events = try await API.shared.events(domain: state.selectedFilter.domain, size: 100)
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
    
    var domain: Domain {
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
}

