import SwiftUI

public enum LoadingState {
    case idle
    case loading(Double)
    case done
}

@Observable public final class AppState: Sendable {
    public var notesSyncState = LoadingState.idle
    public var currentTotalToSync = 0
    public var currentSyncTotal = 0
    
    public init() {}
}
