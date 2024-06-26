import SwiftUI

struct CaptureMenuContents: View {

    let capture: Capture
    let isFavorite: Bool
    
    var body: some View {
        Section {
            if capture.isPhoto {
                Button("Copy", systemImage: "doc.on.doc", intent: CopyCaptureToClipboardIntent(capture: capture))
            }
#if os(visionOS) || os(iOS)
            if capture.isVideo {
                Button("Save Unprocessed Video", systemImage: "film", intent: SaveUnprocessedVideoToCameraRollIntent(capture: capture))
            }
            Button("Save to Camera Roll", systemImage: "square.and.arrow.down", intent: SaveCaptureToCameraRollIntent(capture: capture))
#endif
            Button(
                isFavorite ? "Unfavorite" : "Favorite",
                systemImage: "heart",
                intent: FavoriteCapturesIntent(
                    action: isFavorite ? .remove : .add,
                    captures: [capture]
                )
            )
            .symbolVariant(isFavorite ? .slash : .none)
        }
        Section {
            Button(
                "Delete",
                systemImage: "trash",
                role: .destructive,
                intent: DeleteCapturesIntent(entities: [capture], confirmBeforeDeleting: false)
            )
        }
    }
}

