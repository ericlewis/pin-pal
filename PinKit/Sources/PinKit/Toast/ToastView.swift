import SwiftUI

public enum Toast {
    case none
    case captureSaved
    case downloadingCapture
    case error
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
            .symbolVariant(.circle)
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

