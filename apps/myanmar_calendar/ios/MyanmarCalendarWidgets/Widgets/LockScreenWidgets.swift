import SwiftUI
import WidgetKit

/// Lock-screen widgets draw in one tint over the wallpaper, so they use
/// `.primary` and the moon's shape rather than the style's colours.
private struct LockShell<Content: View>: View {
    let entry: PayloadEntry
    let link: String
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
        .widgetURL(widgetLink(link))
    }
}

struct LockScreenMoonWidget: Widget {
    let kind = "LockScreenMoonWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StyleIntent.self, provider: PayloadProvider<StyleIntent>()) { entry in
            LockShell(entry: entry, link: "day/\(DayKey.string(entry.date))") { _, day in
                ZStack {
                    AccessoryWidgetBackground()
                    MoonView(illumination: day.il, isWaxing: day.wx, lit: .primary, shade: .primary.opacity(0.22))
                        .padding(9)
                }
            }
        }
        .configurationDisplayName("Moon")
        .description("Tonight's moon.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockScreenDayWidget: Widget {
    let kind = "LockScreenDayWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StyleIntent.self, provider: PayloadProvider<StyleIntent>()) { entry in
            LockShell(entry: entry, link: "day/\(DayKey.string(entry.date))") { payload, day in
                ZStack {
                    AccessoryWidgetBackground()
                    VStack(spacing: -2) {
                        Text(payload.s.weekdaysShort[day.wd].uppercased())
                            .font(.system(size: 10, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text(payload.num(Calendar.current.component(.day, from: entry.date)))
                            .font(.system(size: 22, weight: .bold))
                            .widgetAccentable()
                        Text(day.ln).font(.system(size: 9, weight: .semibold))
                    }
                }
            }
        }
        .configurationDisplayName("Day")
        .description("The date and the lunar day.")
        .supportedFamilies([.accessoryCircular])
    }
}

struct LockScreenDateWidget: Widget {
    let kind = "LockScreenDateWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StyleIntent.self, provider: PayloadProvider<StyleIntent>()) { entry in
            LockShell(entry: entry, link: "day/\(DayKey.string(entry.date))") { payload, day in
                HStack(spacing: 8) {
                    MoonView(illumination: day.il, isWaxing: day.wx, lit: .primary, shade: .primary.opacity(0.25))
                        .frame(width: 26, height: 26)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(day.my)
                            .font(.system(size: 14, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .widgetAccentable()
                        Text(subtitle(payload, day))
                            .font(.system(size: 12))
                            .lineLimit(1)
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

    private func subtitle(_ payload: WidgetPayload, _ day: WidgetPayload.Day) -> String {
        if day.isSabbath { return payload.s.sabbath }
        if let holiday = day.hol.first { return holiday }
        let next = payload.upcoming(from: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
            .first { $0.k == "sabbath" || $0.k == "holiday" }
        guard let next, let days = payload.daysUntil(next.d, from: .now) else { return day.lu }
        return "\(next.n) · \(payload.countdown(days))"
    }
}

struct LockScreenLineWidget: Widget {
    let kind = "LockScreenLineWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StyleIntent.self, provider: PayloadProvider<StyleIntent>()) { entry in
            LockShell(entry: entry, link: "today") { _, day in
                Text(day.my)
            }
        }
        .configurationDisplayName("Myanmar date line")
        .description("The Myanmar date above the clock.")
        .supportedFamilies([.accessoryInline])
    }
}
