import SwiftUI
import WidgetKit

/// `mmcalendar://<path>?homeWidget`; the app opens the matching screen.
func widgetLink(_ path: String) -> URL {
    URL(string: "mmcalendar://\(path)?homeWidget")!
}

/// The frame every home-screen widget shares: its style's background with
/// the motif in the corner, the tap link, and the empty state before the
/// app has written any data.
struct WidgetShell<Content: View>: View {
    let entry: PayloadEntry
    var link: String = "today"
    @ViewBuilder let content: (WidgetPayload, WidgetPayload.Day, WidgetLook) -> Content

    @Environment(\.colorScheme) private var scheme

    var body: some View {
        let look = WidgetLook(styleName: entry.styleName, payload: entry.payload, scheme: scheme)
        Group {
            if let payload = entry.payload, let day = entry.day {
                content(payload, day, look)
                    .foregroundStyle(look.palette.ink)
            } else {
                OpenAppView()
            }
        }
        .containerBackground(for: .widget) {
            ZStack(alignment: .topTrailing) {
                look.palette.bg
                MotifView(look: look).offset(x: 16, y: -10)
            }
        }
        .widgetURL(widgetLink(link))
    }
}

extension View {
    /// Myanmar script needs a little more line height than Latin.
    func calendarText(_ size: CGFloat, weight: Font.Weight = .regular) -> some View {
        font(.system(size: size, weight: weight)).lineSpacing(1)
    }
}
