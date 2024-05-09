import SwiftUI

struct CallCellView: View {
    let event: CallEvent
    let createdAt: Date
    
    @AccentColor
    private var accentColor: Color
    
    var body: some View {
        LabeledContent {} label: {
            Text(event.peers.map(\.displayName).joined(separator: ","))
                .font(.headline)
                .foregroundStyle(accentColor)
            if let duration = event.duration {
                Text(duration.formatted())
            }
            LabeledContent {
                
            } label: {
                DateTextView(date: createdAt)
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
        }
        .textSelection(.enabled)
    }
}
