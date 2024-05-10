import SwiftUI
import SwiftData

struct AiMicListView: View {
    
    var query: String
    
    var body: some View {
        EventListView(intent: SyncAiMicEventsIntent()) {
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
    }
}
