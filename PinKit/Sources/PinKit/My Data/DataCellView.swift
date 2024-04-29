import SwiftUI

struct DataCellView: View {
    let event: EventContentEnvelope
    
    @AppStorage(Constant.UI_CUSTOM_ACCENT_COLOR_V1)
    private var accentColor: Color = Constant.defaultAppAccentColor
    
    var body: some View {
        VStack(alignment: .leading) {
            switch event.eventData {
            case let .aiMic(event):
                Text(event.request)
                    .font(.headline)
                    .foregroundStyle(accentColor)
                Text(event.response)
            case let .music(event):
                Text("Music Event")
                    .font(.headline)
                    .foregroundStyle(accentColor)
            case let .call(event):
                Text(event.peers.map(\.displayName).joined(separator: ","))
                    .font(.headline)
                    .foregroundStyle(accentColor)
                if let duration = event.duration {
                    Text(duration.formatted())
                }
            case let .translation(event):
                HStack {
                    Text(event.originLanguage)
                        .font(.headline)
                    Spacer()
                    Text(event.targetLanguage)
                        .font(.headline)
                }
                .overlay {
                    Image(systemName: "arrow.forward")
                }
                .foregroundStyle(accentColor)
            case .unknown:
                Text("Unknown")
            }
            Text(event.eventCreationTime, format: .dateTime)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
