import SwiftUI
import SwiftData

struct CapturesScrollGrid: View {
    
    @Environment(\.database)
    private var database
    
    @Environment(HumaneCenterService.self)
    private var service
    
    @Environment(NavigationStore.self)
    private var navigationStore
    
    @Environment(\.isSearching)
    private var isSearching
    
    @AccentColor
    private var tint
    
    @Query
    private var captures: [Capture]
    
    let isLoading: Bool
    
    init(uuids: [UUID]?, order: SortOrder, isLoading: Bool) {
        var descriptor = FetchDescriptor(sortBy: [SortDescriptor(\Capture.createdAt, order: order)])
        if let uuids {
            descriptor.predicate = #Predicate { uuids.contains($0.uuid) }
        }
        self._captures = .init(descriptor)
        self.isLoading = isLoading
    }
    
    var body: some View {
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
    
    private func deleteNotes(at indexSet: IndexSet) {
        Task {
            do {
                for index in indexSet {
                    let note = captures[index]
                    try await database.delete(note)
                    try await service.deleteByNoteId(note.uuid) // TODO: hm
                }
                try await database.save()
            } catch {
                print("Error deleting note: \(error)")
            }
        }
    }
}
