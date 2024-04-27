import SwiftUI

struct MyDataView: View {
    
    struct ViewState {
        var events: [EventContent] = []
        var isLoading = false
    }
    
    @State
    private var state = ViewState()
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(state.events, id: \.eventIdentifier) { event in
                    VStack(alignment: .leading) {
                        Text(event.eventData["request"] ?? "")
                            .font(.headline)
                        Text(event.eventData["response"] ?? "")
                    }
                }
            }
            .refreshable {
                
            }
            .navigationTitle("My Data")
        }
        .overlay {
            if !state.isLoading, state.events.isEmpty {
                ContentUnavailableView("No data yet", systemImage: "person.text.rectangle")
            }
        }
        .task {
            state.isLoading = true
            while !Task.isCancelled {
                await load()
                state.isLoading = false
                try? await Task.sleep(for: .seconds(5))
            }
        }
    }
    
    func load() async {
        do {
            let events = try await API.shared.events(domain: .aiMic, size: 100)
            withAnimation {
                self.state.events = events.content
            }
        } catch {
            print(error)
        }
    }
}

#Preview {
    MyDataView()
}

