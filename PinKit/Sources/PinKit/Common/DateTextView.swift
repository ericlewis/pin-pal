import SwiftUI

struct DateTextView: View {
    
    @AppStorage(Constants.UI_DATE_FORMAT)
    private var dateFormatPreference: DateFormat = .relative
    
    let date: Date
    
    var body: some View {
        if dateFormatPreference == .relative {
            TimelineView(.everyMinute) { ctx in
                Text(date, format: .relative(presentation: .named))
                    .id(ctx.date)
            }
        } else {
            Text(date, format: .dateTime)
        }
    }
}
