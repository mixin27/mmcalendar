import SwiftUI
import WidgetKit

/// Watch-face complications. They draw the payload the watch app saved
/// (see WatchStore), so they keep rolling over each midnight for as long as
/// it lasts (about six months), without the iPhone.
@main
struct WatchComplications: WidgetBundle {
    var body: some Widget {
        MoonComplication()
        DateComplication()
        LineComplication()
        CornerComplication()
    }
}

struct DayEntry: TimelineEntry {
    let date: Date
    let payload: WidgetPayload?

    var day: WidgetPayload.Day? { payload?.day(for: date) }
}

/// One entry now and one at each midnight, up to 60 days or the end of the
/// payload.
struct DayProvider: TimelineProvider {
    func placeholder(in context: Context) -> DayEntry {
        DayEntry(date: .now, payload: PayloadStore.load())
    }

    func getSnapshot(in context: Context, completion: @escaping (DayEntry) -> Void) {
        completion(DayEntry(date: .now, payload: PayloadStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<DayEntry>) -> Void) {
        let payload = PayloadStore.load()
        let today = Calendar.current.startOfDay(for: .now)
        var entries = [DayEntry(date: .now, payload: payload)]
        let available = payload?.days.count ?? 1
        for offset in 1..<min(60, max(available, 2)) {
            if let next = Calendar.current.date(byAdding: .day, value: offset, to: today) {
                entries.append(DayEntry(date: next, payload: payload))
            }
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

/// The empty state and the shared background.
private struct ComplicationShell<Content: View>: View {
    let entry: DayEntry
    @ViewBuilder let content: (WidgetPayload, WidgetPayload.Day) -> Content

    var body: some View {
        Group {
            if let payload = entry.payload, let day = entry.day {
                content(payload, day)
            } else {
                Image(systemName: "calendar")
            }
        }
        .containerBackground(for: .widget) { Color.clear }
    }
}

struct MoonComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WatchMoonComplication", provider: DayProvider()) { entry in
            ComplicationShell(entry: entry) { _, day in
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: 0) {
                        MoonView(illumination: day.il, isWaxing: day.wx, lit: .primary, shade: .primary.opacity(0.22))
                            .frame(width: 22, height: 22)
                        Text(day.ln)
                            .font(.system(size: 12, weight: .bold))
                            .widgetAccentable()
                    }
                }
            }
        }
        .configurationDisplayName("Moon")
        .description("Tonight's moon and the lunar day.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct DateComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WatchDateComplication", provider: DayProvider()) { entry in
            ComplicationShell(entry: entry) { payload, day in
                HStack(spacing: 6) {
                    MoonView(illumination: day.il, isWaxing: day.wx, lit: .primary, shade: .primary.opacity(0.25))
                        .frame(width: 24, height: 24)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(day.my)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                            .widgetAccentable()
                        Text(next(payload, day, on: entry.date))
                            .font(.system(size: 12))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                    }
                    Spacer(minLength: 0)
                }
            }
        }
        .configurationDisplayName("Myanmar date")
        .description("The Myanmar date and the next Sabbath or holiday.")
        .supportedFamilies([.accessoryRectangular])
    }

    private func next(_ payload: WidgetPayload, _ day: WidgetPayload.Day, on date: Date) -> String {
        if day.isSabbath { return payload.s.sabbath }
        if let holiday = day.hol.first { return holiday }
        guard let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: date)),
              let item = payload.upcoming(from: tomorrow).first(where: { $0.k == "sabbath" || $0.k == "holiday" }),
              let days = payload.daysUntil(item.d, from: date)
        else { return day.lu }
        return "\(item.n) · \(payload.countdown(days))"
    }
}

struct LineComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WatchLineComplication", provider: DayProvider()) { entry in
            ComplicationShell(entry: entry) { _, day in
                Text(day.my)
            }
        }
        .configurationDisplayName("Myanmar date line")
        .description("The Myanmar date in one line.")
        .supportedFamilies([.accessoryInline])
    }
}

struct CornerComplication: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "WatchCornerComplication", provider: DayProvider()) { entry in
            ComplicationShell(entry: entry) { _, day in
                MoonView(illumination: day.il, isWaxing: day.wx, lit: .primary, shade: .primary.opacity(0.25))
                    .padding(4)
                    .widgetLabel { Text(day.lu) }
            }
        }
        .configurationDisplayName("Moon corner")
        .description("The moon, with the waxing or waning day.")
        .supportedFamilies([.accessoryCorner])
    }
}
