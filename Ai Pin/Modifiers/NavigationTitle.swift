import SwiftUI

extension View {
    func navigationTitle<S: StringProtocol>(_ title: S, displayMode: NavigationBarItem.TitleDisplayMode = .inline) -> some View {
        self
            .navigationTitle(Text(title))
            .navigationBarTitleDisplayMode(displayMode)
    }
}
