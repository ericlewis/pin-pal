import SwiftUI

struct FavoriteButton: View {
    
    @Environment(HumaneCenterService.self)
    private var service
    
    let note: Note
    
    init(for note: Note) {
        self.note = note
    }
    
    var body: some View {
        Toggle(
            note.isFavorited ? "Unfavorite" : "Favorite",
            systemImage: "heart",
            isOn: Binding(
                get: { note.isFavorited },
                set: { newValue in
                    handleToggle(value: newValue)
                    note.isFavorited = newValue
                }
            )
            .animation()
        )
        .symbolVariant(note.isFavorited ? .slash : .none)
        .toggleStyle(.button)
    }
    
    func handleToggle(value: Bool) {
        if let memoryUuid = note.memoryUuid {
            Task {
                if value {
                    try await service.favoriteById(memoryUuid)
                } else {
                    try await service.unfavoriteById(memoryUuid)
                }
            }
        }
    }
}

