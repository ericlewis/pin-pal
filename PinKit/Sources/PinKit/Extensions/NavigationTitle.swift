import SwiftUI

extension View {
    public func navigationTitle<S: StringProtocol>(_ title: S, displayMode: NavigationBarItem.TitleDisplayMode = .inline) -> some View {
        self
            .navigationTitle(Text(title))
            .navigationBarTitleDisplayMode(displayMode)
    }
}
