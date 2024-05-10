import SwiftUI
import SwiftData

struct MusicEventListView: View {
 
    var query: String

    var body: some View {
        EventListView(intent: SyncMusicEventsIntent(), descriptor: MusicEvent.all()) {
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
    }
}
