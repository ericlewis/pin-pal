import SwiftUI

struct CaptureMenuFavoriteButton: View {
    
    var memory: Memory
    
    @Environment(HumaneCenterService.self)
    private var service
    
    var buttonTitle: LocalizedStringKey {
        (memory.favorite ?? false) ? "Unfavorite" : "Favorite"
    }
    
    var body: some View {
        Button(buttonTitle, systemImage: "heart", action: toggleFavorite)
            .symbolVariant(memory.favorite ? .slash : .none)
    }
    
    func toggleFavorite() {
        Task { @MainActor in
            if memory.favorite {
                try await service.unfavoriteById(memory.uuid)
                memory.favorite = false
            } else {
                try await service.favoriteById(memory.uuid)
                memory.favorite = true
            }
        }
    }
}

struct CaptureMenuContents: View {
    
    @Environment(\.dismiss)
    private var dismiss
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(\.database)
    private var database
    
    var capture: Capture
    
    var body: some View {
        Section {
            Button("Copy", systemImage: "doc.on.doc", action: copyThumbnailToClipboard)
            Button("Save to Camera Roll", systemImage: "square.and.arrow.down", action: saveToCameraRoll)
            if let memory = capture.memory {
                CaptureMenuFavoriteButton(memory: memory)
            }
        }
        Section {
            Button("Delete", systemImage: "trash", role: .destructive, action: delete)
        }
    }
    
    func copyThumbnailToClipboard() {
        Task {
            UIPasteboard.general.image = try await capture.makeThumbnail()
        }
    }
    
    func saveToCameraRoll() {
        Task {
            try await capture.saveToCameraRoll()
        }
    }
    
    func delete() {
        Task {
            do {
                if let memory = capture.memory {
                    try await service.deleteById(memory.uuid)
                    memory.modelContext?.delete(memory)
                }
                await MainActor.run {
                    dismiss()
                }
            } catch {
                print(error)
            }
        }
    }
}

