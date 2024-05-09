import SwiftUI

struct ToastViewModifier: ViewModifier {
    
    @Environment(Navigation.self)
    private var navigationStore
    
    func body(content: Content) -> some View {
        @Bindable var navigationStore = navigationStore
        content
            .overlay(alignment: .bottom) {
                switch navigationStore.showToast {
                case .captureSaved:
                    ToastView("Capture saved to Camera Roll", systemImage: "checkmark")
                case .error:
                    ToastView("An error occurred, try again", systemImage: "xmark")
                case .downloadingCapture:
                    ToastView("Downloading Capture", systemImage: "slowmo", duration: nil)
                        .symbolEffect(.variableColor.reversing, options: .repeating)
                case .none:
                    EmptyView()
                }
            }
    }
}
