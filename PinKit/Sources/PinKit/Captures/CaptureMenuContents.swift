import SwiftUI

struct CaptureMenuContents: View {

    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(\.dismiss)
    private var dismiss
    
    var capture: Capture
    
    var buttonTitle: LocalizedStringKey {
        capture.isFavorited ? "Unfavorite" : "Favorite"
    }
    
    var body: some View {
        Section {
            Button("Copy", systemImage: "doc.on.doc", action: copyThumbnailToClipboard)
            Button("Save to Camera Roll", systemImage: "square.and.arrow.down", action: saveToCameraRoll)
            Button(buttonTitle, systemImage: "heart", action: toggleFavorite)
                .symbolVariant(capture.isFavorited ? .slash : .none)
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
    
    func toggleFavorite() {
        Task {
            if capture.isFavorited {
                try await service.unfavoriteById(capture.uuid)
                capture.isFavorited = false
                try? capture.modelContext?.save()
            } else {
                try await service.favoriteById(capture.uuid)
                capture.isFavorited = true
                try? capture.modelContext?.save()
            }
        }
    }
    
    func delete() {
        Task { @MainActor in
//            capture.modelContext?.delete(capture)
            dismiss()
        }
    }
}

