import SwiftUI

struct TranslationCellView: View {
    let event: RemoteTranslationEvent
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
