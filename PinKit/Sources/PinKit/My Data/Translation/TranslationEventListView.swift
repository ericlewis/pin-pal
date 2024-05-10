import SwiftUI
import SwiftData
import AppIntents

struct TranslationEventListView: View {
    
    var query: String
    
    @State
    private var sortBy: KeyPath<TranslationEvent, Date> = \.createdAt
    
    @State
    private var order: SortOrder = .reverse
    
    var body: some View {
        var descriptor = TranslationEvent.all()
        let _ = descriptor.sortBy = [SortDescriptor<TranslationEvent>(sortBy, order: order)]
        EventListView(intent: SyncTranslationEventsIntent(), descriptor: descriptor) {
            #Predicate<TranslationEvent> {
                if query.isEmpty {
                    true
                } else {
                    $0.originLanguage.contains(query) || $0.targetLanguage.contains(query)
                }
            }
        } content: {
            TranslationCellView(event: $0)
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
    
    func toggle(sortedBy: KeyPath<TranslationEvent, Date>) -> Binding<Bool> {
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
