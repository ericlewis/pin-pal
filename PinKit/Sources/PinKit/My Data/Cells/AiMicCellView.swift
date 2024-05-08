import SwiftUI

struct AiMicCellView: View {
    let event: AiMicEvent
    let createdAt: Date
    
    @AccentColor
    private var accentColor: Color
    
    var body: some View {
        LabeledContent {} label: {
            Text(event.request)
                .font(.headline)
                .foregroundStyle(accentColor)
            Text(event.response)
            DateTextView(date: createdAt)
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .foregroundStyle(.primary)
    }
}
