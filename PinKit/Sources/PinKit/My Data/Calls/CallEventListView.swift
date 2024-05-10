import SwiftUI
import SwiftData

struct CallEventListView: View {
    
    var query: String
    
    var body: some View {
        EventListView(intent: SyncMusicEventsIntent(), descriptor: PhoneCallEvent.all()) {
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
    }
}
