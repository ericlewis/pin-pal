import SwiftUI

struct CaptureMenuContents: View {
    
    @Environment(CapturesRepository.self)
    private var repository
    
    @Environment(\.dismiss)
    private var dismiss
    
    let capture: ContentEnvelope
    
    var body: some View {
        Section {
            Button("Copy", systemImage: "doc.on.doc") {
                Task {
                    await repository.copyToClipboard(capture: capture)
                }
            }
            Button("Save to Camera Roll", systemImage: "square.and.arrow.down") {
                Task {
                    await repository.save(capture: capture)
                }
            }
            Button(capture.favorite ? "Unfavorite" : "Favorite", systemImage: "heart") {
                Task {
                    await repository.toggleFavorite(content: capture)
                }
            }
            .symbolVariant(capture.favorite ? .slash : .none)
        }
        Section {
            Button("Delete", systemImage: "trash", role: .destructive) {
                Task {
                    await repository.remove(content: capture)
                    dismiss()
                }
            }
        }
    }
}

