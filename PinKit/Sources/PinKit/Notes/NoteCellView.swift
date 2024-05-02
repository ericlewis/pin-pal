import SwiftUI

struct NoteCellView: View {
    
    @AccentColor
    private var tint
    
    let note: Note
    
    var body: some View {
        LabeledContent {} label: {
            Text(note.title)
                .foregroundStyle(tint)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .topTrailing) {
                    if note.isFavorited {
                        Image(systemName: "heart")
                            .symbolVariant(.fill)
                            .foregroundStyle(.red)
                    }
                }
            Text(LocalizedStringKey(note.text))
                .lineLimit(note.text.count > 500 ? 5 : nil)
                .foregroundStyle(.primary)
            Text(note.createdAt, format: .dateTime)
                .foregroundStyle(.tertiary)
        }
        .tint(.primary)
    }
}
