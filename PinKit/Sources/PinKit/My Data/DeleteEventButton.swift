import SwiftUI

struct DeleteEventButton<D: DeletableEvent>: View {
    
    let event: D
    
    var body: some View {
        Button(
            "Delete",
            systemImage: "trash",
            role: .destructive,
            intent: DeleteEventsIntent(entities: [event])
        )
        .tint(.red)
    }
}

