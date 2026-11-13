import SwiftUI

/// How many day pages the app shows, starting today.
private let dayPages = 7

struct WatchRootView: View {
    @ObservedObject var store: WatchStore

    var body: some View {
        if let payload = store.payload, payload.day(for: .now) != nil {
            TimelineView(.everyMinute) { context in
                WatchPagesView(payload: payload, today: Calendar.current.startOfDay(for: context.date))
            }
        } else {
            NoDataView()
        }
    }
}

/// Today and the next days, then Coming up, as vertical pages.
struct WatchPagesView: View {
    let payload: WidgetPayload
    let today: Date

    /// Today's page; Debug builds can open on another with the
    /// `MMCAL_WATCH_PAGE` environment variable, for screenshots.
    @State private var page: Int = {
        #if DEBUG
        return ProcessInfo.processInfo.environment["MMCAL_WATCH_PAGE"].flatMap(Int.init) ?? 0
        #else
        return 0
        #endif
    }()

    private var look: WidgetLook { WidgetLook(styleName: "app", payload: payload, scheme: .dark) }

    var body: some View {
        let days = (0..<dayPages).compactMap { offset -> (Date, WidgetPayload.Day)? in
            guard let date = Calendar.current.date(byAdding: .day, value: offset, to: today),
                  let day = payload.day(for: date) else { return nil }
            return (date, day)
        }
        TabView(selection: $page) {
            ForEach(Array(days.enumerated()), id: \.element.1.d) { offset, item in
                DayPageView(payload: payload, date: item.0, day: item.1, offset: offset, palette: look.palette)
                    .tag(offset)
            }
            ComingUpView(payload: payload, today: today, palette: look.palette)
                .tag(days.count)
        }
        .tabViewStyle(.verticalPage)
    }
}

struct DayPageView: View {
    let payload: WidgetPayload
    let date: Date
    let day: WidgetPayload.Day
    let offset: Int
    let palette: Palette

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(palette.accent)
                HStack(alignment: .center, spacing: 10) {
                    MoonView(day: day, palette: palette)
                        .frame(width: 40, height: 40)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(day.ln)
                            .font(.system(size: 26, weight: .bold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                        Text(day.lu)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                Text(day.my)
                    .font(.headline)
                    .fixedSize(horizontal: false, vertical: true)
                Text(payload.westernDate(date, day))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                if day.isSabbath || day.isSabbathEve {
                    Label(day.isSabbath ? payload.s.sabbath : payload.s.sabbathEve, systemImage: "moon.stars.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(palette.sabbath)
                }
                ForEach(day.hol, id: \.self) { name in
                    Label(name, systemImage: "star.fill")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(palette.holiday)
                }
                let events = payload.events(on: date)
                if !events.isEmpty {
                    Divider()
                    ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Circle().fill(Color(argb: event.c)).frame(width: 7, height: 7)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(event.ti)
                                    .font(.footnote)
                                    .strikethrough(event.done)
                                    .lineLimit(2)
                                Text(event.t.map(payload.westernDigits) ?? payload.s.allDay)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var title: String {
        switch offset {
        case 0: return payload.s.today
        case 1: return payload.s.tomorrow
        default: return payload.s.weekdaysShort[day.wd]
        }
    }
}

struct ComingUpView: View {
    let payload: WidgetPayload
    let today: Date
    let palette: Palette

    var body: some View {
        let items = Array(payload.upcoming(from: today).prefix(12))
        List {
            Text(payload.s.comingUp)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(palette.accent)
                .listRowBackground(Color.clear)
            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
            HStack(spacing: 8) {
                Image(systemName: icon(item.k))
                    .foregroundStyle(color(item.k))
                    .frame(width: 18)
                VStack(alignment: .leading, spacing: 1) {
                    Text(item.n).font(.footnote).lineLimit(2)
                    if let days = payload.daysUntil(item.d, from: today) {
                        Text(payload.countdown(days))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            }
        }
    }

    private func icon(_ kind: String?) -> String {
        switch kind {
        case "holiday": return "star.fill"
        case "sabbath": return "moon.stars.fill"
        case "fullMoon": return "circle.fill"
        case "newMoon": return "circle"
        default: return "calendar"
        }
    }

    private func color(_ kind: String?) -> Color {
        switch kind {
        case "holiday": return palette.holiday
        case "sabbath": return palette.sabbath
        default: return palette.moon
        }
    }
}

/// Before the iPhone has sent anything.
struct NoDataView: View {
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "iphone.and.arrow.forward")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("Open Myanmar Calendar on your iPhone to show the calendar here.")
                .font(.footnote)
                .multilineTextAlignment(.center)
        }
        .padding()
    }
}

extension WidgetPayload {
    /// "Friday, 13 Nov 2026" in the app's words and digits.
    func westernDate(_ date: Date, _ day: Day) -> String {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return "\(s.weekdays[day.wd]), \(westernNum(c.day ?? 1)) \(s.monthsShort[(c.month ?? 1) - 1]) \(westernNum(c.year ?? 2000))"
    }

    /// [text] with its ASCII digits in the Western-date digits.
    func westernDigits(_ text: String) -> String {
        let digits = Array(s.westernDigits ?? s.digits)
        guard digits.count == 10 else { return text }
        return String(text.map { ch in ch.wholeNumberValue.map { digits[$0] } ?? ch })
    }
}
