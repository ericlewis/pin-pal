import SwiftUI
import AppIntents

@Observable public final class NoteFilterState {
    
    public var filter = Note.all()
    public var type: NoteFilterType = .all
    public var sort = SortDescriptor<Note>(\.createdAt, order: .reverse)
    public var order = SortOrder.reverse
    
    
    func toggle(sortedBy: KeyPath<Note, String>) -> Binding<Bool> {
        Binding(
            get: { self.sort.keyPath == sortedBy  },
            set: {
                if $0 {
                    withAnimation(.snappy) {
                        self.sort = SortDescriptor<Note>(sortedBy, order: self.order)
                    }
                }
            }
        )
    }
    
    func toggle(sortedBy: KeyPath<Note, Date>) -> Binding<Bool> {
        Binding(
            get: { self.sort.keyPath == sortedBy  },
            set: {
                if $0 {
                    withAnimation(.snappy) {
                        self.sort = SortDescriptor<Note>(sortedBy, order: self.order)
                    }
                }
            }
        )
    }
}

@Observable public final class AppState: Sendable {
    
    public var totalNotesToSync = 0
    public var numberOfNotesSynced = 0
    
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
    
    public init() {}
}
