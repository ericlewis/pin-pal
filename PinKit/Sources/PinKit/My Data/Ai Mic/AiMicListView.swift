import SwiftUI
import SwiftData

struct AiMicListView: View {
    
    var query: String
    
    @State
    private var sortBy: KeyPath<AiMicEvent, Date> = \.createdAt
    
    @State
    private var order: SortOrder = .reverse

    var body: some View {
        var descriptor = AiMicEvent.all()
        let _ = descriptor.sortBy = [SortDescriptor<AiMicEvent>(sortBy, order: order)]
        EventListView(intent: SyncAiMicEventsIntent(), descriptor: descriptor) {
            #Predicate<AiMicEvent> {
                if query.isEmpty {
                    true
                } else {
                    $0.request.contains(query) || $0.response.contains(query)
                }
            }
        } content: {
            AiMicCellView(event: $0)
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
    
    func toggle(sortedBy: KeyPath<AiMicEvent, Date>) -> Binding<Bool> {
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
