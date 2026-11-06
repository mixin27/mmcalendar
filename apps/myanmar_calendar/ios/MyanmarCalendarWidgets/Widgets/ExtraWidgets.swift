import SwiftUI
import WidgetKit

// MARK: - Countdown

struct CountdownWidget: Widget {
    let kind = "CountdownWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: CountdownIntent.self,
            provider: PayloadProvider<CountdownIntent>(countdown: { $0.target })
        ) { entry in
            CountdownView(entry: entry)
        }
        .configurationDisplayName("Countdown")
        .description("Days until the next full moon, Sabbath or Thingyan.")
        .supportedFamilies([.systemSmall])
    }
}

struct CountdownView: View {
    let entry: PayloadEntry

    var body: some View {
        WidgetShell(entry: entry) { payload, _, look in
            let p = look.palette
            let target = target(payload)
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    if let target, let d = payload.day(for: DayKey.date(target.d) ?? entry.date), target.k == "fullMoon" || target.k == "newMoon" {
                        MoonView(day: d, palette: p).frame(width: 30, height: 30)
                    }
                    Spacer()
                    if let target {
                        Chip(text: target.n, foreground: target.k == "thingyan" ? p.holiday : p.accent,
                             background: target.k == "thingyan" ? p.holidaySoft : p.soft)
                    }
                }
                Spacer(minLength: 0)
                if let target, let days = payload.daysUntil(target.d, from: entry.date) {
                    Text(payload.num(days))
                        .font(look.number(52, for: payload.num(days)))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("\(payload.s.daysUnit) · \(formatted(target.d, payload))")
                        .calendarText(12)
                        .foregroundStyle(p.muted)
                        .lineLimit(1)
                }
            }
        }
    }

    private func target(_ payload: WidgetPayload) -> WidgetPayload.Upcoming? {
        let option = entry.countdown == .standard
            ? CountdownOption(rawValue: payload.prefs.cd) ?? .fullMoon
            : entry.countdown
        switch option {
        case .thingyan:
            return payload.thingyan.map { .init(d: $0.d, k: "thingyan", n: $0.n) }
        case .sabbath:
            return payload.upcoming(from: entry.date).first { $0.k == "sabbath" }
        case .newMoon:
            return payload.upcoming(from: entry.date).first { $0.k == "newMoon" }
        default:
            return payload.upcoming(from: entry.date).first { $0.k == "fullMoon" }
        }
    }

    private func formatted(_ key: String, _ payload: WidgetPayload) -> String {
        guard let date = DayKey.date(key) else { return key }
        let month = Calendar.current.component(.month, from: date)
        return "\(payload.westernNum(Calendar.current.component(.day, from: date))) \(payload.s.monthsShort[month - 1])"
    }
}

// MARK: - Astrology

struct AstrologyWidget: Widget {
    let kind = "AstrologyWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StyleIntent.self, provider: PayloadProvider<StyleIntent>()) { entry in
            AstrologyView(entry: entry)
        }
        .configurationDisplayName("Astrology day")
        .description("Today's good and inauspicious days, and the next good day.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct AstrologyView: View {
    let entry: PayloadEntry
    @Environment(\.widgetFamily) private var family
    private let good = Color(red: 0.12, green: 0.62, blue: 0.39)

    var body: some View {
        WidgetShell(entry: entry, link: "day/\(DayKey.string(entry.date))") { payload, day, look in
            let p = look.palette
            let headline = day.avoid.first ?? day.good.first
            let isBad = !day.avoid.isEmpty
            let today = VStack(alignment: .leading, spacing: 3) {
                Text(payload.s.today.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(p.muted)
                Text(headline ?? day.lu)
                    .calendarText(19, weight: .bold)
                    .foregroundStyle(headline == nil ? p.ink : (isBad ? p.holiday : good))
                    .lineLimit(2)
                    .minimumScaleFactor(0.7)
                Text(headline == nil ? payload.s.plainDay : (isBad ? payload.s.avoidDay : payload.s.goodDay))
                    .calendarText(11.5)
                    .foregroundStyle(p.muted)
                    .lineLimit(2)
                Spacer(minLength: 0)
                if day.isSabbath || day.isSabbathEve {
                    Chip(text: day.isSabbath ? payload.s.sabbath : payload.s.sabbathEve,
                         foreground: p.sabbath, background: p.soft)
                }
            }
            if family == .systemSmall {
                today
            } else {
                HStack(spacing: 12) {
                    today.frame(maxWidth: .infinity, alignment: .leading)
                    Rectangle().fill(p.line).frame(width: 1)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(payload.s.nextGoodDay.uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(p.muted)
                        if let next = nextGood(payload) {
                            Text(next.day.good.first ?? "")
                                .calendarText(15, weight: .bold)
                                .foregroundStyle(good)
                            Text("\(payload.s.weekdays[next.day.wd]) · \(payload.countdown(next.inDays))")
                                .calendarText(11.5)
                                .foregroundStyle(p.muted)
                        }
                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }

    private func nextGood(_ payload: WidgetPayload) -> (day: WidgetPayload.Day, inDays: Int)? {
        let key = DayKey.string(entry.date)
        guard let day = payload.days.first(where: { $0.d > key && !$0.good.isEmpty && $0.avoid.isEmpty }),
              let n = payload.daysUntil(day.d, from: entry.date) else { return nil }
        return (day, n)
    }
}

// MARK: - Today's note

struct NoteWidget: Widget {
    let kind = "NoteWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StyleIntent.self, provider: PayloadProvider<StyleIntent>()) { entry in
            NoteView(entry: entry)
        }
        .configurationDisplayName("Today's note")
        .description("Your note for today; tap to open the day and write one.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct NoteView: View {
    let entry: PayloadEntry

    var body: some View {
        WidgetShell(entry: entry, link: "day/\(DayKey.string(entry.date))") { payload, day, look in
            let p = look.palette
            let note = payload.notes?.first(where: { $0.d == day.d })?.t
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text((payload.s.note ?? "Note").uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(p.muted)
                    Spacer(minLength: 4)
                    Text(day.lu)
                        .calendarText(11)
                        .foregroundStyle(p.muted)
                        .lineLimit(1)
                }
                if let note {
                    Text(note)
                        .calendarText(14)
                        .foregroundStyle(p.ink)
                        .lineLimit(6)
                } else {
                    Text(payload.s.addNote ?? "Add a note")
                        .calendarText(15, weight: .semibold)
                        .foregroundStyle(p.accent)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

// MARK: - Good days

struct GoodDaysWidget: Widget {
    let kind = "GoodDaysWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StyleIntent.self, provider: PayloadProvider<StyleIntent>()) { entry in
            GoodDaysView(entry: entry)
        }
        .configurationDisplayName("Good days")
        .description("The next days with good astrological marks.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct GoodDaysView: View {
    let entry: PayloadEntry
    @Environment(\.widgetFamily) private var family
    private let good = Color(red: 0.12, green: 0.62, blue: 0.39)

    var body: some View {
        WidgetShell(entry: entry, link: "today") { payload, _, look in
            let p = look.palette
            let key = DayKey.string(entry.date)
            // Good and nothing to avoid: the app's good-day rule.
            let days = payload.days
                .filter { $0.d >= key && !$0.good.isEmpty && $0.avoid.isEmpty }
                .prefix(family == .systemSmall ? 2 : 3)
            VStack(alignment: .leading, spacing: 5) {
                Text((payload.s.goodDays ?? "Good days").uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(p.muted)
                if days.isEmpty {
                    Text(payload.s.noGoodDays ?? "No good days soon")
                        .calendarText(13)
                        .foregroundStyle(p.muted)
                }
                ForEach(Array(days), id: \.d) { day in
                    Link(destination: widgetLink("day/\(day.d)")) {
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            VStack(alignment: .leading, spacing: 1) {
                                Text(label(payload, day))
                                    .calendarText(13, weight: .semibold)
                                    .foregroundStyle(p.ink)
                                    .lineLimit(1)
                                Text(day.good.joined(separator: " · "))
                                    .calendarText(11)
                                    .foregroundStyle(good)
                                    .lineLimit(1)
                            }
                            Spacer(minLength: 4)
                            if family != .systemSmall,
                               let n = payload.daysUntil(day.d, from: entry.date) {
                                Text(payload.countdown(n))
                                    .calendarText(11)
                                    .foregroundStyle(p.muted)
                                    .lineLimit(1)
                            }
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    /// "Mon 30 Nov".
    private func label(_ payload: WidgetPayload, _ day: WidgetPayload.Day) -> String {
        guard let date = DayKey.date(day.d) else { return day.lu }
        let c = Calendar.current.dateComponents([.day, .month], from: date)
        let month = payload.s.monthsShort[(c.month ?? 1) - 1]
        return "\(payload.s.weekdaysShort[day.wd]) \(payload.westernNum(c.day ?? 1)) \(month)"
    }
}

// MARK: - Myanmar year

struct YearWidget: Widget {
    let kind = "YearWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StyleIntent.self, provider: PayloadProvider<StyleIntent>()) { entry in
            YearView(entry: entry)
        }
        .configurationDisplayName("Myanmar year")
        .description("How far through the Myanmar year we are.")
        .supportedFamilies([.systemSmall])
    }
}

struct YearView: View {
    let entry: PayloadEntry

    var body: some View {
        WidgetShell(entry: entry) { payload, _, look in
            let p = look.palette
            let progress = progress(payload)
            ZStack {
                Circle().stroke(p.soft, lineWidth: 10)
                Circle()
                    .trim(from: 0, to: progress)
                    .stroke(p.accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .widgetAccentable()
                VStack(spacing: 9) {
                    Text(payload.year.n).font(look.number(20, for: payload.year.n)).lineLimit(1).minimumScaleFactor(0.6)
                    Text(payload.year.month).calendarText(11).foregroundStyle(p.muted).lineLimit(1).minimumScaleFactor(0.7)
                }
                .padding(.horizontal, 16)
            }
            .padding(6)
        }
    }

    private func progress(_ payload: WidgetPayload) -> Double {
        guard let start = DayKey.date(payload.year.start), let end = DayKey.date(payload.year.end) else { return 0 }
        let total = end.timeIntervalSince(start)
        return total > 0 ? min(max(entry.date.timeIntervalSince(start) / total, 0), 1) : 0
    }
}
