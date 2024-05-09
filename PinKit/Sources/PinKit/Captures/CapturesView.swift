import SwiftUI

struct CapturesView: View {
    
    @Environment(CapturesRepository.self)
    private var repository

    @State
    private var query = ""
    
    var body: some View {
        NavigationStack {
            SearchableCapturesGridView(query: $query)
                .refreshable(action: repository.reload)
                .searchable(text: $query)
                .listSectionSpacing(15)
                .navigationTitle("Captures")
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button("Select") {
                            
                        }
                        .disabled(true)
                    }
                    ToolbarItemGroup(placement: .secondaryAction) {
                        Button("Aspect Ratio Grid", systemImage: "rectangle.arrowtriangle.2.inward") {
                            
                        }
                        .disabled(true)
                        Menu("Filter", systemImage: "line.3.horizontal.decrease.circle") {
                            Toggle("All Items", systemImage: "photo.on.rectangle", isOn: .constant(true))
                            Section {
                                Button("Favorites", systemImage: "heart") {
                                    
                                }
                                Button("Photos", systemImage: "photo") {
                                    
                                }
                                Button("Videos", systemImage: "video") {
                                    
                                }
                            }
                            .disabled(true)
                        }
                    }
                }
        }
        .task(repository.initial)
    }
}

#Preview {
    CapturesView()
        .environment(HumaneCenterService.live())
}
