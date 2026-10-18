import Foundation

/// `widget_data_v2`, written by the app (WidgetPayloadBuilder in
/// packages/features/home_widgets). Everything a widget draws comes from
/// here, including every word, so nothing is hard-coded on this side.
struct WidgetPayload: Decodable {
    let v: Int
    let lang: String
    let gen: String
    let start: String
    let s: Strings
    let days: [Day]
    let months: [String: Month]
    let upcoming: [Upcoming]
    let thingyan: Upcoming?
    let events: [Event]
    let year: Year
    let styles: [String: StylePair]
    let prefs: Prefs

    struct Strings: Decodable {
        let today, tomorrow, inDays, daysUnit, comingUp, events, noEvents, allDay: String
        let nextGoodDay, goodDay, avoidDay, plainDay, myanmarYear, thingyan: String
        let fullMoonIn, newMoonIn, holidays, digits, sabbath, sabbathEve: String
        let moonPhases, weekdays, weekdaysShort, months, monthsShort: [String]
    }

    struct Day: Decodable {
        let d: String
        let wd: Int
        let my: String
        let lu: String
        let ln: String
        let ph: Int
        let il: Double
        let wx: Bool
        let hol: [String]
        let sab: Int
        let good: [String]
        let avoid: [String]
        let info: [String]

        var isSabbath: Bool { sab == 1 }
        var isSabbathEve: Bool { sab == 2 }
        var isMoonDay: Bool { ph == 1 || ph == 3 }
    }

    struct Month: Decodable {
        let title: String
        let sub: String
        let cells: [Cell]

        struct Cell: Decodable {
            let d: Int
            let `in`: Bool
            let ln: String
            let ph: Int
            let hol: Bool
            let sab: Bool
        }
    }

    struct Upcoming: Decodable {
        let d: String
        let k: String?
        let n: String
    }

    struct Event: Decodable {
        let d: String
        let t: String?
        let ti: String
        let c: Int
        let id: Int?
        let done: Bool
    }

    struct Year: Decodable {
        let n: String
        let start: String
        let end: String
        let month: String
    }

    struct StylePair: Decodable {
        let light: [String: Int]
        let dark: [String: Int]
    }

    struct Prefs: Decodable {
        let style: String
        let hol: Bool
        let sab: Bool
        let ast: Bool
        let ev: Bool
        let cd: String
    }
}

// MARK: - Loading

enum PayloadStore {
    static let appGroup = "group.dev.mixin27.mmcalendar"
    static let key = "widget_data_v2"

    private static var cached: (raw: String, payload: WidgetPayload)?

    /// The latest payload the app wrote, decoded once per change.
    static func load() -> WidgetPayload? {
        guard let raw = UserDefaults(suiteName: appGroup)?.string(forKey: key) else {
            return nil
        }
        if let cached, cached.raw == raw { return cached.payload }
        guard let data = raw.data(using: .utf8),
              let payload = try? JSONDecoder().decode(WidgetPayload.self, from: data)
        else { return nil }
        cached = (raw, payload)
        return payload
    }
}

// MARK: - Dates and numbers

enum DayKey {
    private static let formatter: DateFormatter = {
        let f = DateFormatter()
        f.calendar = Calendar(identifier: .gregorian)
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = .current
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    static func string(_ date: Date) -> String { formatter.string(from: date) }
    static func date(_ key: String) -> Date? { formatter.date(from: key) }
    static func monthKey(_ date: Date) -> String { String(string(date).prefix(7)) }
}

extension WidgetPayload {
    func day(for date: Date) -> Day? {
        let key = DayKey.string(date)
        return days.first { $0.d == key }
    }

    /// [value] in the calendar language's digits.
    func num(_ value: Int) -> String {
        let digits = Array(s.digits)
        guard digits.count == 10 else { return "\(value)" }
        return String(String(value).map { ch in
            ch.wholeNumberValue.map { digits[$0] } ?? ch
        })
    }

    /// "in 8 days", "Tomorrow" or "Today".
    func countdown(_ days: Int) -> String {
        switch days {
        case 0: return s.today
        case 1: return s.tomorrow
        default: return s.inDays.replacingOccurrences(of: "{n}", with: num(days))
        }
    }

    func daysUntil(_ key: String, from date: Date) -> Int? {
        guard let target = DayKey.date(key) else { return nil }
        let start = Calendar.current.startOfDay(for: date)
        return Calendar.current.dateComponents([.day], from: start, to: target).day
    }

    /// Coming-up items from [date] on.
    func upcoming(from date: Date) -> [Upcoming] {
        let key = DayKey.string(date)
        return upcoming.filter { $0.d >= key }
    }

    func events(on date: Date) -> [Event] {
        let key = DayKey.string(date)
        return events.filter { $0.d == key }
    }

    func monthTitle(_ date: Date) -> String {
        let month = Calendar.current.component(.month, from: date)
        let year = Calendar.current.component(.year, from: date)
        return "\(s.months[month - 1]) \(num(year))"
    }
}
