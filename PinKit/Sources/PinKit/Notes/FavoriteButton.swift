import SwiftUI

struct FavoriteButton: View {
    
    @Environment(HumaneCenterService.self)
    private var service
    
    var note: Note

    var body: some View {
        if let memory = note.memory {
            Toggle(
                memory.favorite ? "Unfavorite" : "Favorite",
                systemImage: "heart",
                isOn: Binding(
                    get: { memory.favorite },
                    set: { newValue in
                        memory.favorite = newValue
                        handleToggle(value: newValue)
                    }
                )
                .animation()
            )
            .symbolVariant(memory.favorite ? .slash : .none)
            .toggleStyle(.button)
            .tint(.pink)
        }
    }
    
    func handleToggle(value: Bool) {
        if let uuid = note.memory?.uuid {
            Task {
                if value {
                    try await service.favoriteById(uuid)
                } else {
                    try await service.unfavoriteById(uuid)
                }
            }
        }
    }
}

