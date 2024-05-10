import SwiftUI
import Models

struct AiMicCellView: View {
    
    @AccentColor
    private var accentColor: Color

    var event: AiMicEvent

    var body: some View {
        LabeledContent {} label: {
            Text(event.request)
                .font(.headline)
                .foregroundStyle(accentColor)
            Text(event.response)
            LabeledContent {
                AiMicFeedbackButton(event: event, category: event.feedbackCategory)
            } label: {
                DateTextView(date: event.createdAt)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .foregroundStyle(.primary)
        .textSelection(.enabled)
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            DeleteEventButton(event: event)
        }
    }
}

struct AiMicFeedbackButton: View {
    
    let event: AiMicEvent
    let category: FeedbackCategory?
    
    func makeNegativeFeedbackButton(reason: NegativeFeedbackReason) -> some View {
        Button(
            NegativeFeedbackReason.caseDisplayRepresentations[reason]?.title.key ?? "",
            intent: NegativeAiMicEventFeedbackIntent(event: event, reason: reason)
        )
    }
    
    var body: some View {
        HStack {
            Menu {
                if category == nil {
                    Section {
                        Button("Good Response", systemImage: "hand.thumbsup", intent: PositiveAiMicEventFeedbackIntent(event: event))
                        Menu("Needs Improvement", systemImage: "hammer") {
                            ForEach(NegativeFeedbackReason.allCases, id: \.rawValue) { reason in
                                makeNegativeFeedbackButton(reason: reason)
                            }
                        }
                    }
                }
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
                    .foregroundStyle(.secondary)
                    .foregroundStyle(.orange)
                case .positive:
                    HStack(spacing: 5) {
                        Text("Good Response")
                        Image(systemName: "hand.thumbsup")
                    }
                    .imageScale(.small)
                    .foregroundStyle(.secondary)
                    .foregroundStyle(.green)
                }
            }
            .font(.footnote)
            .frame(maxWidth: .greatestFiniteMagnitude, alignment: .trailing)
        }
        .font(.caption)
        .foregroundStyle(.tertiary)
    }
}
