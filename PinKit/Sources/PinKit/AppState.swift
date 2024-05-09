import SwiftUI

@Observable public final class AppState: Sendable {
    
    public var totalNotesToSync = 0
    public var numberOfNotesSynced = 0
    
    public var totalAiMicEventsToSync = 0
    public var numberOfAiMicEventsSynced = 0
    
    public init() {}
}
