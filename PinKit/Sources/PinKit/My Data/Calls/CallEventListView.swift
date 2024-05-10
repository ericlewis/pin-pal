import SwiftUI
import SwiftData

struct CallEventListView: View {
    
    var query: String
    
    @State
    private var sortBy: KeyPath<PhoneCallEvent, Date> = \.createdAt
    
    @State
    private var order: SortOrder = .reverse
    
    var body: some View {
        var descriptor = PhoneCallEvent.all()
        let _ = descriptor.sortBy = [SortDescriptor<PhoneCallEvent>(sortBy, order: order)]
        EventListView(intent: SyncMusicEventsIntent(), descriptor: descriptor) {
            #Predicate<PhoneCallEvent> {
                if query.isEmpty {
                    true
                } else {
                    $0.peers.contains(query)
                }
            }
        } content: {
            CallCellView(event: $0)
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
    
    func toggle(sortedBy: KeyPath<PhoneCallEvent, Date>) -> Binding<Bool> {
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
