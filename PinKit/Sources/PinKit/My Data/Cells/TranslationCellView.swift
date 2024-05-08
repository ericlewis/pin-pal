import SwiftUI

struct TranslationCellView: View {
    let event: TranslationEvent
    let createdAt: Date
    
    @AccentColor
    private var accentColor: Color
    
    var body: some View {
        LabeledContent {} label: {
            HStack {
                Text(event.originLanguage)
                    .font(.headline)
                Spacer()
                Text(event.targetLanguage)
                    .font(.headline)
            }
            .overlay {
                Image(systemName: "arrow.forward")
            }
            .foregroundStyle(accentColor)
            DateTextView(date: createdAt)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
