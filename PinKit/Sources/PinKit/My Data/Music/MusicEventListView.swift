import SwiftUI
import SwiftData

struct MusicEventListView: View {
    
    var query: String
    
    @State
    private var sortBy: KeyPath<MusicEvent, Date> = \.createdAt
    
    @State
    private var order: SortOrder = .reverse
    
    var body: some View {
        var descriptor = MusicEvent.all()
        let _ = descriptor.sortBy = [SortDescriptor<MusicEvent>(sortBy, order: order)]
        EventListView(intent: SyncMusicEventsIntent(), descriptor: descriptor) {
            #Predicate<MusicEvent> {
                if query.isEmpty {
                    true
                } else {
                    $0.artistName?.contains(query) == true || $0.albumName?.contains(query) == true
                }
            }
        } content: {
            MusicCellView(event: $0)
        }
        .toolbar {
            ToolbarItem(placement: .secondaryAction) {
                Menu("Sort", systemImage: "arrow.up.arrow.down") {
                    Toggle("Created At", isOn: toggle(sortedBy: \.createdAt))
                    Section("Order") {
                        Picker("Order", selection: $order.animation()) {
                            Label("Ascending", systemImage: "arrow.up").tag(SortOrder.forward)
                            Label("Descending", systemImage: "arrow.down").tag(SortOrder.reverse)
                        }
                    }
                }
            }
        }
    }
    
    func toggle(sortedBy: KeyPath<MusicEvent, Date>) -> Binding<Bool> {
        Binding(
            get: { self.sortBy == sortedBy  },
            set: {
                if $0 {
                    withAnimation(.snappy) {
                        self.sortBy = sortedBy
                    }
                }
            }
        )
    }
}
