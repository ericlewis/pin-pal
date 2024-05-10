import SwiftUI

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
    
    public init() {}
}
