import SwiftUI

struct AiMicCellView: View {
    let event: AiMicEvent
    let feedbackCategory: FeedbackCategory?
    let createdAt: Date
    
    @AccentColor
    private var accentColor: Color

    var body: some View {
        LabeledContent {} label: {
            Text(event.request)
                .font(.headline)
                .foregroundStyle(accentColor)
            Text(event.response)
            HStack {
                DateTextView(date: createdAt)
                Spacer()
                Menu {
                    Button("Good Response", systemImage: "hand.thumbsup") {
                        // self.feedbackState = .positive
                    }
                    Button("Needs Improvement", systemImage: "hammer", role: .destructive) {
                        // self.feedbackState = .negative
                    }
                } label: {
                    switch feedbackCategory {
                    case .none:
                        HStack(spacing: 5) {
                            Text("Feedback")
                            Image(systemName: "chevron.up.chevron.down")
                        }
                        .imageScale(.small)
                    case .negative:
                        HStack(spacing: 5) {
                            Text("Needs Improvement")
                            Image(systemName: "hammer")
                        }
                        .imageScale(.small)
                        .foregroundStyle(.orange)
                    case .positive:
                        HStack(spacing: 5) {
                            Text("Good Response")
                            Image(systemName: "hand.thumbsup")
                        }
                        .imageScale(.small)
                        .foregroundStyle(.green)                        
                    }
                }
                .font(.footnote)
            }
            .font(.caption)
            .foregroundStyle(.tertiary)
        }
        .foregroundStyle(.primary)
        .textSelection(.enabled)
    }
}
