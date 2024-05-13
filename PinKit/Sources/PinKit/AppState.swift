import SwiftUI
import AppIntents

@Observable 
public final class NoteFilterState {
    public var filter = Note.all()
    public var type: NoteFilterType = .all
    public var sort = SortDescriptor<Note>(\.createdAt, order: .reverse)
    public var order = SortOrder.reverse
}

@Observable 
public final class CaptureFilterState {
    
    public enum Filter {
        case all
        case photo
        case video
        case favorites
    }
    
    public var filter = Capture.all()
    public var type = Filter.all
    public var order = SortOrder.reverse
    public var sort = SortDescriptor<Capture>(\.createdAt, order: .reverse)
    
    
    func toggle(sortedBy: KeyPath<Capture, Date>) -> Binding<Bool> {
        Binding(
            get: { self.sort.keyPath == sortedBy  },
            set: {
                if $0 {
                    withAnimation(.snappy) {
                        self.sort = SortDescriptor<Capture>(sortedBy, order: self.order)
                    }
                }
            }
        )
    }
    
    func toggle(filter: Filter) -> Binding<Bool> {
        Binding(
            get: {
                self.type == filter
            },
            set: { isOn in
                if isOn, self.type != filter {
                    withAnimation(.snappy) {
                        self.type = filter
                    }
                } else {
                    withAnimation(.snappy) {
                        self.type = .all
                    }
                }
            }
        )
    }
}

@Observable public final class AppState: Sendable {
    
    public var isNotesLoading = false
    public var totalNotesToSync = 0
    public var numberOfNotesSynced = 0
    
    public var isCapturesLoading = false
    public var totalCapturesToSync = 0
    public var numberOfCapturesSynced = 0
    
    public var totalAiMicEventsToSync = 0
    public var numberOfAiMicEventsSynced = 0
    
    public var totalCallEventsToSync = 0
    public var numberOfCallEventsSynced = 0
    
    public var totalTranslationEventsToSync = 0
    public var numberOfTranslationEventsSynced = 0
    
    public var totalMusicEventsToSync = 0
    public var numberOfMusicEventsSynced = 0
    
    public var noteFilter = NoteFilterState()
    public var captureFilter = CaptureFilterState()

    public init() {}
}
