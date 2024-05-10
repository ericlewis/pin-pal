import SwiftUI

public enum Toast {
    case none
    case captureSaved
    case downloadingCapture
    case error
    case favorited
    case unfavorited
    case copiedToClipboard
    case sentFeedback
}

struct ToastView: View {
    
    @Environment(Navigation.self)
    private var navigation
    
    let title: LocalizedStringKey
    let systemImage: String
    var duration: Duration?
    
    init(_ title: LocalizedStringKey, systemImage: String, duration: Duration? = .seconds(3)) {
        self.title = title
        self.systemImage = systemImage
        self.duration = duration
    }
    
    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.footnote.bold())
            .padding()
            .background(RoundedRectangle(cornerRadius: 15).fill(.bar))
            .padding(.bottom, 70)
            .task {
                if let duration {
                    try? await Task.sleep(for: duration)
                    navigation.dismissToast()
                }
            }
            .transition(.scale(0.8, anchor: .top).combined(with: .opacity))
            .animation(.spring, value: navigation.showToast)
    }
}

struct ToastViewModifier: ViewModifier {
    
    @Environment(Navigation.self)
    private var navigation
    
    func body(content: Content) -> some View {
        @Bindable var navigation = navigation
        content
            .overlay(alignment: .bottom) {
                Group {
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
                    case .sentFeedback:
                        ToastView("Feedback Sent", systemImage: "checkmark")
                    case .downloadingCapture:
                        ToastView("Downloading Capture", systemImage: "slowmo", duration: nil)
                            .symbolEffect(.variableColor.reversing, options: .repeating)
                    case .none:
                        EmptyView()
                    }
                }
                .onTapGesture {
                    navigation.dismissToast()
                }
            }
    }
}
