import SwiftUI

struct SyncStatusView: View {
    
    @Environment(AppState.self)
    private var app
    
    let current: KeyPath<AppState, Int>
    let total: KeyPath<AppState, Int>

    var body: some View {
        if app[keyPath: total] > 0, app[keyPath: current] > 0 {
            let current = Double(app[keyPath: current])
            let total = Double(app[keyPath: total])
            ProgressView(value:  current / total)
                .padding(.horizontal, -5)
        }
    }
}

