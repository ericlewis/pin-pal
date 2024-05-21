import SwiftUI
import AppIntents
import SwiftData
import MarkdownUI

struct SearchableNotesListView: View {
    
    @Environment(\.isSearching)
    private var isSearching
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(\.database)
    private var database
    
    @AccentColor
    private var accentColor
    
    var isLoading: Bool
    var isFirstLoad: Bool
    
    @Query
    var notes: [Note]
    
    init(filter: FetchDescriptor<Note>, isLoading: Bool, isFirstLoad: Bool) {
        self._notes = .init(filter)
        self.isLoading = isLoading
        self.isFirstLoad = isFirstLoad
    }
    
    var body: some View {
        List {
            ForEach(notes) { note in
                Button(intent: OpenNoteIntent(note: note)) {
                    LabeledContent {} label: {
                        LabeledContent {
                            if note.isFavorite {
                                Image(systemName: "heart")
                                    .symbolVariant(.fill)
                                    .imageScale(.small)
                                    .foregroundStyle(.pink)
                                    .offset(x: 10)
                            }
                        } label: {
                            Text(note.name)
                                .font(.headline)
                                .foregroundStyle(accentColor)
                        }
                        Markdown(note.body)
                            .markdownTheme(
                                Theme()
                                    .text {
                                        ForegroundColor(.primary)
                                    }
                                    .link {
                                        ForegroundColor(accentColor)
                                    }
                            )
                        LabeledContent {
                            
                        } label: {
                            DateTextView(date: note.modifiedAt)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .textSelection(.enabled)
                    .tint(.primary)
                }
                .swipeActions(edge: .leading, allowsFullSwipe: true) {
                    FavoriteNoteButton(note: note, favorite: note.isFavorite)
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    DeleteNoteButton(note: note)
                }
            }
            .contentShape(Rectangle())
#if os(visionOS)
            .buttonStyle(.plain)
            .buttonBorderShape(.roundedRectangle)
#endif
        }
        .overlay {
            if notes.isEmpty, isSearching, !isLoading {
                ContentUnavailableView.search
            } else if notes.isEmpty, isLoading {
                ProgressView("This may take a little while.")
            } else if notes.isEmpty, !isSearching, !isFirstLoad {
                ContentUnavailableView("No notes yet", systemImage: "note.text")
            }
        }
    }
}

struct FavoriteNoteButton: View {
    
    var note: Note
    var favorite: Bool
    
    var body: some View {
        Button(
            favorite ? "Unfavorite" : "Favorite",
            systemImage: "heart",
            intent: FavoriteNotesIntent(action: favorite ? .remove : .add, notes: [note])
        )
        .symbolVariant(favorite ? .slash : .none)
        .tint(.pink)
    }
}

struct DeleteNoteButton: View {
    
    let note: Note
    
    var body: some View {
        Button(
            "Delete",
            systemImage: "trash",
            role: .destructive,
            intent: DeleteNotesIntent(entities: [note], confirmBeforeDeleting: false)
        )
        .tint(.red)
    }
}
