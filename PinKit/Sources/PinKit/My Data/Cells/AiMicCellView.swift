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
            LabeledContent {
                AiMicFeedbackButton(category: feedbackCategory)
            } label: {
                DateTextView(date: createdAt)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .textSelection(.enabled)
    }
}

struct AiMicFeedbackButton: View {
    
    let category: FeedbackCategory?
    
    var body: some View {
        HStack {
            Menu {
                Section {
                    Button("Good Response", systemImage: "hand.thumbsup") {
                        // self.feedbackState = .positive
                    }
                    Button("Needs Improvement", systemImage: "hammer", role: .destructive) {
                        // self.feedbackState = .negative
                    }
                }
                .disabled(true)
            } label: {
                switch category {
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
                    .foregroundStyle(.tertiary)
                    .foregroundStyle(.orange)
                case .positive:
                    HStack(spacing: 5) {
                        Text("Good Response")
                        Image(systemName: "hand.thumbsup")
                    }
                    .imageScale(.small)
                    .foregroundStyle(.tertiary)
                    .foregroundStyle(.green)
                }
            }
            .font(.footnote)
        }
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
}
