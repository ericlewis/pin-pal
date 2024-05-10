import SwiftUI
import SwiftData
import AppIntents

struct TranslationEventListView: View {

    var query: String

    var body: some View {
        EventListView(intent: SyncTranslationEventsIntent()) {
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
    }
}
