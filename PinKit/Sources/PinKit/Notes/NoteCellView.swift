import SwiftUI

struct NoteCellView: View {
    
    @AccentColor
    private var tint
    
    let note: Note
    
    var body: some View {
        LabeledContent {} label: {
            Text(note.title)
                .lineLimit(2)
                .foregroundStyle(tint)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
                .overlay(alignment: .leading) {
                    if note.memory?.favorite == true {
                        Image(systemName: "heart")
                            .symbolVariant(.fill)
                            .imageScale(.small)
                            .foregroundStyle(.red)
                            .offset(x: -20)
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
