import SwiftUI

struct CallCellView: View {
    
    var event: PhoneCallEvent
    
    @AccentColor
    private var accentColor: Color
    
    var body: some View {
        LabeledContent {} label: {
            Text(event.peers.joined(separator: ","))
                .font(.headline)
                .foregroundStyle(accentColor)
            if let duration = event.dur {
                Text(duration.formatted())
            }
            LabeledContent {
                
            } label: {
                DateTextView(date: event.createdAt)
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
        }
        .textSelection(.enabled)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            DeleteEventButton(event: event)
        }
    }
}
