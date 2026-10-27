import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Month

struct MonthWidget: Widget {
    let kind = "MonthWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StyleIntent.self, provider: PayloadProvider<StyleIntent>()) { entry in
            MonthWidgetView(entry: entry)
        }
        .configurationDisplayName("Month")
        .description("The month with Western and Myanmar days. Use the arrows to see other months.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct MonthWidgetView: View {
    let entry: PayloadEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let offset = MonthOffset.current(on: entry.date)
        let monthDate = Calendar.current.date(byAdding: .month, value: offset, to: entry.date) ?? entry.date
        let key = DayKey.monthKey(monthDate)
        WidgetShell(entry: entry, link: "month/\(key)") { payload, day, look in
            let p = look.palette
            if let month = payload.months[key] {
                if family == .systemMedium {
                    HStack(alignment: .top, spacing: 12) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(payload.s.monthsShort[Calendar.current.component(.month, from: monthDate) - 1].uppercased())
                                .font(.system(size: 12, weight: .bold))
                                .foregroundStyle(p.accent)
                            Text(month.sub).calendarText(12, weight: .semibold).lineLimit(3).minimumScaleFactor(0.8)
                            Spacer(minLength: 2)
                            arrows(look)
                        }
                        .frame(width: 92, alignment: .leading)
                        MonthGridView(payload: payload, month: month, monthDate: monthDate, today: entry.date, look: look, dense: true)
                    }
                } else {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 0) {
                                Text(month.title).font(.system(size: 17, weight: .bold)).lineLimit(1)
                                Text(month.sub).calendarText(11.5).foregroundStyle(p.muted).lineLimit(1)
                            }
                            Spacer()
                            arrows(look)
                        }
                        MonthGridView(payload: payload, month: month, monthDate: monthDate, today: entry.date, look: look, dense: false)
                    }
                }
            } else {
                Text(payload.monthTitle(monthDate)).font(.headline)
            }
        }
    }

    private func arrows(_ look: WidgetLook) -> some View {
        HStack(spacing: 6) {
            ForEach([-1, 1], id: \.self) { delta in
                Button(intent: ChangeMonthIntent(delta: delta)) {
                    Image(systemName: delta < 0 ? "chevron.left" : "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 26, height: 26)
                        .foregroundStyle(look.palette.accent)
                        .background(look.palette.soft, in: Circle())
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Coming up

struct ComingUpWidget: Widget {
    let kind = "ComingUpWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StyleIntent.self, provider: PayloadProvider<StyleIntent>()) { entry in
            ComingUpView(entry: entry)
        }
        .configurationDisplayName("Coming up")
        .description("The next holidays, Sabbath days and full moons, with how far away they are.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct ComingUpView: View {
    let entry: PayloadEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        WidgetShell(entry: entry) { payload, _, look in
            let p = look.palette
            let prefs = payload.prefs
            let items = payload.upcoming(from: entry.date).filter { item in
                switch item.k {
                case "holiday": return prefs.hol
                case "sabbath": return prefs.sab
                default: return true
                }
            }
            VStack(alignment: .leading, spacing: family == .systemLarge ? 10 : 7) {
                Text(payload.s.comingUp.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(p.accent)
                ForEach(Array(items.prefix(family == .systemLarge ? 7 : 3).enumerated()), id: \.offset) { _, item in
                    Link(destination: widgetLink("day/\(item.d)")) {
                        row(item, payload: payload, look: look)
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }

    private func row(_ item: WidgetPayload.Upcoming, payload: WidgetPayload, look: WidgetLook) -> some View {
        let p = look.palette
        let holiday = item.k == "holiday"
        let day = DayKey.date(item.d).map { Calendar.current.component(.day, from: $0) } ?? 0
        let days = payload.daysUntil(item.d, from: entry.date) ?? 0
        return HStack(spacing: 10) {
            Text(payload.westernNum(day))
                .font(look.number(14, for: payload.westernNum(day)))
                .monospacedDigit()
                .foregroundStyle(holiday ? p.holiday : p.accent)
                .frame(width: 34, height: 34)
                .background(holiday ? p.holidaySoft : p.soft, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 0) {
                Text(item.n).calendarText(13, weight: .semibold).lineLimit(1)
                Text(payload.countdown(days)).calendarText(11).foregroundStyle(p.muted)
            }
            Spacer(minLength: 0)
            if item.k == "fullMoon" || item.k == "newMoon", let d = payload.day(for: DayKey.date(item.d) ?? entry.date) {
                MoonView(day: d, palette: p).frame(width: 18, height: 18)
            }
        }
    }
}

// MARK: - Agenda

struct AgendaWidget: Widget {
    let kind = "AgendaWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: StyleIntent.self, provider: PayloadProvider<StyleIntent>()) { entry in
            AgendaView(entry: entry)
        }
        .configurationDisplayName("Agenda")
        .description("Today's and tomorrow's events with the Myanmar date.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct AgendaView: View {
    let entry: PayloadEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        WidgetShell(entry: entry, link: "events") { payload, day, look in
            let p = look.palette
            let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: entry.date)!
            let today = payload.events(on: entry.date)
            let next = payload.events(on: tomorrow)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .center, spacing: 8) {
                    let number = payload.westernNum(Calendar.current.component(.day, from: entry.date))
                    Text(number)
                        .font(look.number(28, for: number))
                    VStack(alignment: .leading, spacing: 0) {
                        Text(payload.s.weekdays[day.wd].uppercased())
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(p.holiday)
                        Text(day.my).calendarText(11).foregroundStyle(p.muted).lineLimit(1)
                    }
                    Spacer()
                    Link(destination: widgetLink("events/new")) {
                        Image(systemName: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .frame(width: 26, height: 26)
                            .foregroundStyle(p.accent)
                            .background(p.soft, in: Circle())
                    }
                }
                Rectangle().fill(p.line).frame(height: 1)
                if today.isEmpty {
                    Text(payload.s.noEvents).calendarText(13).foregroundStyle(p.muted)
                } else {
                    ForEach(Array(today.prefix(family == .systemLarge ? 4 : 2).enumerated()), id: \.offset) { _, event in
                        Link(destination: widgetLink(event.id.map { "event/\($0)" } ?? "events")) {
                            EventRow(event: event, payload: payload, palette: p)
                        }
                    }
                }
                if family == .systemLarge, !next.isEmpty {
                    Text("\(payload.s.tomorrow)".uppercased())
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(p.muted)
                        .padding(.top, 6)
                    ForEach(Array(next.prefix(3).enumerated()), id: \.offset) { _, event in
                        Link(destination: widgetLink(event.id.map { "event/\($0)" } ?? "events")) {
                            EventRow(event: event, payload: payload, palette: p)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
    }
}
