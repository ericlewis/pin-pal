import SwiftUI
import SwiftData

struct CapturesScrollGrid: View {
 
    @Environment(\.isSearching)
    private var isSearching

    @Query
    private var captures: [Capture]
    
    let isLoading: Bool
    
    init(uuids: [UUID]?, order: SortOrder, isLoading: Bool) {
        var descriptor = FetchDescriptor(sortBy: [SortDescriptor(\Capture.createdAt, order: order)])
        if let uuids {
            descriptor.predicate = #Predicate<Capture> {
                if let memory = $0.memory {
                    return uuids.contains(memory.uuid)
                } else {
                    return false
                }
            }
        }
        self._captures = .init(descriptor)
        self.isLoading = isLoading
    }
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100, maximum: 200), spacing: 2)], spacing: 2) {
                ForEach(captures) { capture in
                    NavigationLink {
                        CaptureDetailView(capture: capture)
                    } label: {
                        CaptureCellView(capture: capture)
                    }
                    .contextMenu {
                        CaptureMenuContents(capture: capture)
                    }
                }
            }
        }
        .overlay {
            if isLoading, captures.isEmpty {
                ProgressView()
            } else if isSearching, !isLoading, captures.isEmpty {
                ContentUnavailableView.search
            } else if captures.isEmpty {
                ContentUnavailableView("No captures yet", systemImage: "camera.aperture")
            }
        }
    }
}
