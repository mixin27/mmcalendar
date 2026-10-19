import SwiftUI
import WidgetKit

// MARK: - Today

struct TodayWidget: Widget {
    let kind = "TodayWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StyleIntent.self, provider: PayloadProvider<StyleIntent>()) { entry in
            TodayView(entry: entry)
        }
        .configurationDisplayName("Today")
        .description("The date, the Myanmar date, the moon and what makes today special.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

struct TodayView: View {
    let entry: PayloadEntry
    @Environment(\.widgetFamily) private var family
    @Environment(\.showsWidgetContainerBackground) private var hasBackground

    var body: some View {
        WidgetShell(entry: entry, link: "day/\(DayKey.string(entry.date))") { payload, day, look in
            let p = look.palette
            let dayNumber = payload.num(Calendar.current.component(.day, from: entry.date))
            let month = payload.s.months[Calendar.current.component(.month, from: entry.date) - 1]
            let chips = TodayChips(payload: payload, day: day, look: look)
            switch family {
            case .systemSmall:
                VStack(alignment: .leading, spacing: 0) {
                    Text(payload.s.weekdays[day.wd].uppercased())
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(p.holiday)
                    Text(dayNumber)
                        .font(look.number(hasBackground ? 52 : 64))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text(month).calendarText(12.5).foregroundStyle(p.muted)
                    Spacer(minLength: 2)
                    HStack(spacing: 6) {
                        MoonView(day: day, palette: p).frame(width: 18, height: 18)
                        Text(day.lu).calendarText(12.5, weight: .semibold).lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            case .systemMedium:
                HStack(alignment: .top, spacing: 14) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(payload.s.weekdays[day.wd].uppercased())
                            .font(.system(size: 12, weight: .bold))
                            .foregroundStyle(p.holiday)
                        Text(dayNumber).font(look.number(50)).lineLimit(1).minimumScaleFactor(0.6)
                        Text(payload.monthTitle(entry.date)).calendarText(12.5).foregroundStyle(p.muted)
                    }
                    .frame(width: 112, alignment: .leading)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(spacing: 8) {
                            MoonView(day: day, palette: p).frame(width: 30, height: 30)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(day.my).calendarText(14, weight: .bold).lineLimit(2).minimumScaleFactor(0.8)
                                Text("\(payload.s.myanmarYear) \(payload.year.n)").calendarText(11.5).foregroundStyle(p.muted)
                            }
                        }
                        Spacer(minLength: 0)
                        chips
                    }
                }
            default:
                VStack(alignment: .leading, spacing: 4) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 0) {
                            Text(payload.s.weekdays[day.wd].uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(p.holiday)
                            Text(dayNumber).font(look.number(56)).lineLimit(1)
                            Text(payload.monthTitle(entry.date)).calendarText(13).foregroundStyle(p.muted)
                        }
                        Spacer()
                        MoonView(day: day, palette: p).frame(width: 64, height: 64)
                    }
                    Text(day.my).calendarText(15, weight: .bold)
                    Text("\(payload.s.myanmarYear) \(payload.year.n)").calendarText(12).foregroundStyle(p.muted)
                    chips.padding(.top, 2)
                    Spacer(minLength: 4)
                    ForEach(Array(comingUp(payload).prefix(2).enumerated()), id: \.offset) { _, item in
                        Link(destination: widgetLink("day/\(item.d)")) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.k == "holiday" ? p.holiday : (item.k == "sabbath" ? p.sabbath : p.moon))
                                    .frame(width: 6, height: 6)
                                Text(item.n).calendarText(13, weight: .semibold).lineLimit(1)
                                Spacer(minLength: 4)
                                Text(payload.countdown(payload.daysUntil(item.d, from: entry.date) ?? 0))
                                    .calendarText(11.5)
                                    .foregroundStyle(p.muted)
                                    .lineLimit(1)
                            }
                        }
                    }
                    Spacer(minLength: 4)
                    Rectangle().fill(p.line).frame(height: 1)
                    WeekStripView(payload: payload, start: entry.date, look: look)
                }
            }
        }
    }
}

extension TodayView {
    /// The next two items after today, honouring the holiday and Sabbath toggles.
    func comingUp(_ payload: WidgetPayload) -> [WidgetPayload.Upcoming] {
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: entry.date)!
        let tomorrowKey = DayKey.string(tomorrow)
        return payload.upcoming(from: tomorrow).filter { item in
            // Tomorrow's Sabbath is already a chip.
            if item.k == "sabbath" && item.d == tomorrowKey { return false }
            switch item.k {
            case "holiday": return payload.prefs.hol
            case "sabbath": return payload.prefs.sab
            default: return true
            }
        }
    }
}

/// Sabbath, a holiday and an astrological day, as chips; fewer when the
/// row is narrow.
struct TodayChips: View {
    let payload: WidgetPayload
    let day: WidgetPayload.Day
    let look: WidgetLook

    private struct Item: Identifiable {
        let id: Int
        let text: String
        let foreground: Color
        let background: Color
    }

    var body: some View {
        let list = items
        ViewThatFits(in: .horizontal) {
            row(list)
            row(Array(list.prefix(2)))
            row(Array(list.prefix(1)))
        }
    }

    private func row(_ list: [Item]) -> some View {
        HStack(spacing: 6) {
            ForEach(list) { Chip(text: $0.text, foreground: $0.foreground, background: $0.background) }
        }
    }

    private var items: [Item] {
        let p = look.palette
        let prefs = payload.prefs
        let next = Calendar.current.date(byAdding: .day, value: 1, to: DayKey.date(day.d) ?? .now)!
        var list: [(String, Color, Color)] = []
        if prefs.sab {
            if day.isSabbath {
                list.append((payload.s.sabbath, p.sabbath, p.soft))
            } else if payload.day(for: next)?.isSabbath == true {
                list.append(("\(payload.s.tomorrow) · \(payload.s.sabbath)", p.accent, p.soft))
            }
        }
        if prefs.hol, let holiday = day.hol.first {
            list.append((holiday, p.holiday, p.holidaySoft))
        }
        if prefs.ast, let avoid = day.avoid.first {
            list.append((avoid, p.holiday, p.holidaySoft))
        } else if prefs.ast, let good = day.good.first {
            list.append((good, p.accent, p.soft))
        }
        return list.enumerated().map { Item(id: $0.offset, text: $0.element.0, foreground: $0.element.1, background: $0.element.2) }
    }
}

// MARK: - Moon

struct MoonWidget: Widget {
    let kind = "MoonWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StyleIntent.self, provider: PayloadProvider<StyleIntent>()) { entry in
            MoonWidgetView(entry: entry)
        }
        .configurationDisplayName("Moon")
        .description("Tonight's moon, the lunar day and the next full or new moon.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MoonWidgetView: View {
    let entry: PayloadEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        WidgetShell(entry: entry, link: "day/\(DayKey.string(entry.date))") { payload, day, look in
            let p = look.palette
            let next = nextMoon(payload)
            if family == .systemSmall {
                VStack(spacing: 4) {
                    MoonView(day: day, palette: p).frame(maxWidth: 88, maxHeight: 88)
                    Text(day.lu).calendarText(14, weight: .bold).lineLimit(1)
                    if let next { Text(next).calendarText(11.5).foregroundStyle(p.muted).lineLimit(1).minimumScaleFactor(0.7) }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                HStack(spacing: 16) {
                    MoonView(day: day, palette: p).frame(width: 112, height: 112)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(day.my).calendarText(15, weight: .bold).lineLimit(2).minimumScaleFactor(0.8)
                        if let next { Text(next).calendarText(12.5, weight: .semibold).foregroundStyle(p.accent) }
                        Spacer(minLength: 4)
                        HStack {
                            ForEach([0, 2, 4, 6, 8], id: \.self) { offset in
                                let date = Calendar.current.date(byAdding: .day, value: offset, to: entry.date)!
                                VStack(spacing: 3) {
                                    if let d = payload.day(for: date) {
                                        MoonView(day: d, palette: p).frame(width: 22, height: 22)
                                    }
                                    Text(payload.num(Calendar.current.component(.day, from: date)))
                                        .font(.system(size: 10.5)).monospacedDigit().foregroundStyle(p.muted)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
            }
        }
    }

    /// "Full moon in 8 days", from the next moon in coming up.
    private func nextMoon(_ payload: WidgetPayload) -> String? {
        guard let item = payload.upcoming(from: entry.date)
            .first(where: { $0.k == "fullMoon" || $0.k == "newMoon" }),
            let days = payload.daysUntil(item.d, from: entry.date)
        else { return nil }
        if days == 0 { return item.n }
        let template = item.k == "fullMoon" ? payload.s.fullMoonIn : payload.s.newMoonIn
        return template.replacingOccurrences(of: "{n}", with: payload.num(days))
    }
}

// MARK: - Week

struct WeekWidget: Widget {
    let kind = "WeekWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StyleIntent.self, provider: PayloadProvider<StyleIntent>()) { entry in
            WeekWidgetView(entry: entry)
        }
        .configurationDisplayName("Week")
        .description("Seven days with moons and Sabbath days, and today's first event.")
        .supportedFamilies([.systemMedium])
    }
}

struct WeekWidgetView: View {
    let entry: PayloadEntry

    var body: some View {
        WidgetShell(entry: entry) { payload, day, look in
            let p = look.palette
            VStack(alignment: .leading, spacing: 6) {
                WeekStripView(payload: payload, start: entry.date, look: look)
                Rectangle().fill(p.line).frame(height: 1)
                if payload.prefs.ev, let event = payload.events(on: entry.date).first {
                    Link(destination: widgetLink(event.id.map { "event/\($0)" } ?? "events")) {
                        EventRow(event: event, payload: payload, palette: p, subtitle: day.my)
                    }
                } else {
                    Text(day.my).calendarText(13, weight: .semibold).lineLimit(1)
                }
            }
        }
    }
}

/// A coloured bar, the title and its time.
struct EventRow: View {
    let event: WidgetPayload.Event
    let payload: WidgetPayload
    let palette: Palette
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 1.5)
                .fill(Color(argb: event.c))
                .frame(width: 3, height: 28)
            VStack(alignment: .leading, spacing: 0) {
                Text(event.ti)
                    .font(.system(size: 13, weight: .semibold))
                    .strikethrough(event.done)
                    .lineLimit(1)
                Text([event.t ?? payload.s.allDay, subtitle].compactMap { $0 }.joined(separator: " · "))
                    .calendarText(11)
                    .foregroundStyle(palette.muted)
                    .lineLimit(1)
            }
        }
    }
}
