import SwiftUI

struct TranslationCellView: View {
    
    var event: TranslationEvent
    
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
            LabeledContent {
                
            } label: {
                DateTextView(date: event.createdAt)
                    .foregroundStyle(.tertiary)
                    .font(.caption)
            }
        }
        .textSelection(.enabled)
    }
}
