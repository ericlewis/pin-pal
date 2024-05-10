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
                    ToastView("Capture saved to Camera Roll", systemImage: "checkmark")
                case .error:
                    ToastView("An error occurred, try again", systemImage: "xmark")
                case .favorited:
                    ToastView("Favorited", systemImage: "heart")
                case .unfavorited:
                    ToastView("Unfavorited", systemImage: "heart")
                        .symbolVariant(.slash)
                case .copiedToClipboard:
                    ToastView("Copied", systemImage: "doc.on.doc")
                case .downloadingCapture:
                    ToastView("Downloading Capture", systemImage: "slowmo", duration: nil)
                        .symbolEffect(.variableColor.reversing, options: .repeating)
                case .none:
                    EmptyView()
                }
            }
    }
}
