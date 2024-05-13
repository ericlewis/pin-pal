import SwiftUI

struct SortNotesToggle: View {
    
    let name: LocalizedStringKey
    let sortBy: KeyPath<Note, String>?
    let sortBy2: KeyPath<Note, Date>?

    init(_ name: LocalizedStringKey, sortBy: KeyPath<Note, String>) {
        self.name = name
        self.sortBy = sortBy
        self.sortBy2 = nil
    }
    
    init(_ name: LocalizedStringKey, sortBy: KeyPath<Note, Date>) {
        self.name = name
        self.sortBy = nil
        self.sortBy2 = sortBy
    }
    
    @Environment(AppState.self)
    private var app
    
    var body: some View {
        if let sortBy2 {
            Toggle(name, isOn: app.noteFilter.sort.keyPath == sortBy2, intent: SortNotesIntent(sortBy: sortBy2))
        } else if let sortBy {
            Toggle(name, isOn: app.noteFilter.sort.keyPath == sortBy, intent: SortNotesIntent(sortBy: sortBy))
        }
    }
}

