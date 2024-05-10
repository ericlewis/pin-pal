import SwiftUI

struct ToastViewModifier: ViewModifier {
    
    @Environment(Navigation.self)
    private var navigation
    
    func body(content: Content) -> some View {
        @Bindable var navigation = navigation
        content
            .overlay(alignment: .bottom) {
                switch navigation.showToast {
                case .captureSaved:
                    ToastView("Capture saved", systemImage: "checkmark")
                case .error:
                    ToastView("An error occurred", systemImage: "xmark")
                case .favorited:
                    ToastView("Favorited Capture", systemImage: "heart")
                case .unfavorited:
                    ToastView("Unfavorited Capture", systemImage: "heart")
                        .symbolVariant(.slash)
                case .copiedToClipboard:
                    ToastView("Copied Capture", systemImage: "doc.on.doc")
                case .downloadingCapture:
                    ToastView("Downloading Capture", systemImage: "slowmo", duration: nil)
                        .symbolEffect(.variableColor.reversing, options: .repeating)
                case .none:
                    EmptyView()
                }
            }
    }
}
