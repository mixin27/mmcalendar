import SwiftUI
import WidgetKit

private enum WidgetConstants {
    static let appGroupId = "group.dev.mixin27.mmcalendar"
    static let timelineKey = "widget_timeline_v1"
    static let monthTimelineKey = "widget_month_timeline_v1"
}

struct MyanmarCalendarEntry: TimelineEntry {
    let date: Date
    let westernDate: String
    let myanmarDate: String
    let moonPhase: String
    let moonPhaseEmoji: String
    let fortnightDay: String
    let holidays: String
    let sabbathInfo: String
    let astrologicalDays: String
    let month: MyanmarMonthSnapshot?
    let weekdayNames: [String]
}

struct MyanmarMonthSnapshot {
    let myanmarYear: Int
    let myanmarMonthName: String
    let westernYear: Int
    let westernMonthName: String
    let days: [MyanmarMonthDay]
}

struct MyanmarMonthDay {
    let westernYear: Int
    let westernMonth: Int
    let westernDay: Int
    let moonPhase: Int
    let fortnightDay: Int
    let hasHoliday: Bool
    let isCurrentMonth: Bool
}

struct MyanmarCalendarProvider: TimelineProvider {
    func placeholder(in context: Context) -> MyanmarCalendarEntry {
        MyanmarCalendarEntry.placeholder
    }

    func getSnapshot(
        in context: Context,
        completion: @escaping (MyanmarCalendarEntry) -> Void
    ) {
        completion(WidgetDataStore.snapshot(for: Date()))
    }

    func getTimeline(
        in context: Context,
        completion: @escaping (Timeline<MyanmarCalendarEntry>) -> Void
    ) {
        let entries = WidgetDataStore.timelineEntries()
        let calendar = Calendar.autoupdatingCurrent
        let nextMidnight = calendar.date(
            byAdding: .day,
            value: 1,
            to: calendar.startOfDay(for: Date())
        ) ?? Date().addingTimeInterval(60 * 60)

        if entries.count > 1 {
            completion(Timeline(entries: entries, policy: .atEnd))
        } else {
            completion(Timeline(entries: entries, policy: .after(nextMidnight)))
        }
    }
}

private enum WidgetDataStore {
    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: WidgetConstants.appGroupId)
    }

    static func timelineEntries() -> [MyanmarCalendarEntry] {
        guard
            let timeline = jsonDictionary(forKey: WidgetConstants.timelineKey),
            let rawEntries = timeline["entries"] as? [String: Any]
        else {
            return [snapshot(for: Date())]
        }

        let monthTimeline = jsonDictionary(forKey: WidgetConstants.monthTimelineKey)
        let today = Calendar.autoupdatingCurrent.startOfDay(for: Date())
        let entries = rawEntries.compactMap { key, value -> MyanmarCalendarEntry? in
            guard
                let date = date(from: key),
                date >= today,
                let data = value as? [String: Any]
            else {
                return nil
            }
            return makeEntry(
                date: date,
                data: data,
                dateKey: key,
                monthTimeline: monthTimeline
            )
        }.sorted { $0.date < $1.date }

        return entries.isEmpty ? [snapshot(for: Date())] : entries
    }

    static func snapshot(for date: Date) -> MyanmarCalendarEntry {
        let key = dateKey(from: date)
        let timeline = jsonDictionary(forKey: WidgetConstants.timelineKey)
        let rawEntries = timeline?["entries"] as? [String: Any]
        let data = rawEntries?[key] as? [String: Any]
        let monthTimeline = jsonDictionary(forKey: WidgetConstants.monthTimelineKey)

        return makeEntry(
            date: date,
            data: data ?? scalarData(),
            dateKey: key,
            monthTimeline: monthTimeline
        )
    }

    private static func makeEntry(
        date: Date,
        data: [String: Any],
        dateKey: String,
        monthTimeline: [String: Any]?
    ) -> MyanmarCalendarEntry {
        MyanmarCalendarEntry(
            date: date,
            westernDate: string(data, "western_date"),
            myanmarDate: string(data, "myanmar_date"),
            moonPhase: string(data, "moon_phase"),
            moonPhaseEmoji: string(data, "moon_phase_emoji", fallback: "🌙"),
            fortnightDay: string(data, "fortnight_day"),
            holidays: string(data, "holidays"),
            sabbathInfo: string(data, "sabbath_info"),
            astrologicalDays: string(data, "astrological_days"),
            month: monthSnapshot(for: dateKey, timeline: monthTimeline),
            weekdayNames: weekdayNames()
        )
    }

    private static func scalarData() -> [String: Any] {
        guard let defaults else { return [:] }
        let keys = [
            "western_date", "myanmar_date", "moon_phase",
            "moon_phase_emoji", "fortnight_day", "holidays",
            "sabbath_info", "astrological_days",
        ]
        return Dictionary(uniqueKeysWithValues: keys.compactMap { key in
            defaults.object(forKey: key).map { (key, $0) }
        })
    }

    private static func monthSnapshot(
        for dateKey: String,
        timeline: [String: Any]?
    ) -> MyanmarMonthSnapshot? {
        guard
            let dateToMonth = timeline?["date_to_month_key"] as? [String: Any],
            let monthKey = dateToMonth[dateKey] as? String,
            let monthEntries = timeline?["month_entries"] as? [String: Any],
            let month = monthEntries[monthKey] as? [String: Any],
            let rawDays = month["days"] as? [[String: Any]]
        else {
            return nil
        }

        let days = rawDays.compactMap { raw -> MyanmarMonthDay? in
            guard
                let year = int(raw, "western_year"),
                let month = int(raw, "western_month"),
                let day = int(raw, "western_day")
            else {
                return nil
            }
            return MyanmarMonthDay(
                westernYear: year,
                westernMonth: month,
                westernDay: day,
                moonPhase: int(raw, "moon_phase") ?? 0,
                fortnightDay: int(raw, "fortnight_day") ?? 0,
                hasHoliday: raw["has_holiday"] as? Bool ?? false,
                isCurrentMonth: raw["is_current_month"] as? Bool ?? true
            )
        }

        return MyanmarMonthSnapshot(
            myanmarYear: int(month, "myanmar_year") ?? 0,
            myanmarMonthName: string(month, "myanmar_month_name"),
            westernYear: int(month, "western_year") ?? 0,
            westernMonthName: string(month, "western_month_name"),
            days: days
        )
    }

    private static func weekdayNames() -> [String] {
        guard
            let raw = defaults?.string(forKey: "weekday_names"),
            !raw.isEmpty
        else {
            return ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        }
        let names = raw.split(separator: ",").map {
            String($0).trimmingCharacters(in: .whitespaces)
        }
        return names.count == 7 ? names : ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    }

    private static func jsonDictionary(forKey key: String) -> [String: Any]? {
        guard
            let value = defaults?.string(forKey: key),
            let data = value.data(using: .utf8),
            let object = try? JSONSerialization.jsonObject(with: data)
        else {
            return nil
        }
        return object as? [String: Any]
    }

    private static func string(
        _ dictionary: [String: Any],
        _ key: String,
        fallback: String = ""
    ) -> String {
        if let value = dictionary[key] as? String { return value }
        if let value = dictionary[key] as? NSNumber { return value.stringValue }
        return fallback
    }

    private static func int(_ dictionary: [String: Any], _ key: String) -> Int? {
        if let value = dictionary[key] as? Int { return value }
        if let value = dictionary[key] as? NSNumber { return value.intValue }
        return nil
    }

    private static func date(from key: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: key)
    }

    private static func dateKey(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = .autoupdatingCurrent
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private extension MyanmarCalendarEntry {
    static var placeholder: MyanmarCalendarEntry {
        MyanmarCalendarEntry(
            date: Date(),
            westernDate: "12 September 2026",
            myanmarDate: "မြန်မာပြက္ခဒိန်",
            moonPhase: "Moon phase",
            moonPhaseEmoji: "🌕",
            fortnightDay: "15",
            holidays: "",
            sabbathInfo: "",
            astrologicalDays: "",
            month: nil,
            weekdayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        )
    }
}

private extension View {
    @ViewBuilder
    func calendarWidgetBackground() -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(Color(red: 0.95, green: 0.98, blue: 0.93), for: .widget)
        } else {
            background(Color(red: 0.95, green: 0.98, blue: 0.93))
        }
    }
}

struct CompactDateWidgetView: View {
    let entry: MyanmarCalendarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(entry.westernDate)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(entry.myanmarDate)
                .font(.system(size: 18, weight: .semibold))
                .minimumScaleFactor(0.65)
            Spacer(minLength: 0)
            HStack {
                Text(entry.moonPhaseEmoji)
                Text(entry.moonPhase)
                    .font(.caption2)
                    .lineLimit(1)
            }
        }
        .calendarWidgetBackground()
    }
}

struct CompactDateWidget: Widget {
    let kind = "CompactDateWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MyanmarCalendarProvider()) { entry in
            CompactDateWidgetView(entry: entry)
        }
        .configurationDisplayName("Myanmar Date")
        .description("Shows today's Western and Myanmar calendar dates.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct MoonPhaseWidgetView: View {
    let entry: MyanmarCalendarEntry

    var body: some View {
        VStack(spacing: 7) {
            Text(entry.moonPhaseEmoji)
                .font(.system(size: 48))
            Text(entry.moonPhase)
                .font(.headline)
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
            if !entry.fortnightDay.isEmpty {
                Text(entry.fortnightDay)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .calendarWidgetBackground()
    }
}

struct MoonPhaseWidget: Widget {
    let kind = "MoonPhaseWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MyanmarCalendarProvider()) { entry in
            MoonPhaseWidgetView(entry: entry)
        }
        .configurationDisplayName("Moon Phase")
        .description("Shows today's Myanmar calendar moon phase.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct FullCalendarWidgetView: View {
    let entry: MyanmarCalendarEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.westernDate)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(entry.myanmarDate)
                        .font(.system(size: 18, weight: .bold))
                        .minimumScaleFactor(0.65)
                }
                Spacer()
                Text(entry.moonPhaseEmoji)
                    .font(.system(size: 34))
            }

            Divider()
            Label(entry.moonPhase, systemImage: "moon.stars.fill")
                .font(.caption)
            if !entry.holidays.isEmpty {
                Label(entry.holidays, systemImage: "calendar.badge.exclamationmark")
                    .font(.caption)
                    .lineLimit(2)
            }
            if !entry.sabbathInfo.isEmpty {
                Label(entry.sabbathInfo, systemImage: "sparkles")
                    .font(.caption)
                    .lineLimit(1)
            }
            if !entry.astrologicalDays.isEmpty {
                Text(entry.astrologicalDays)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .calendarWidgetBackground()
    }
}

struct FullCalendarWidget: Widget {
    let kind = "FullCalendarWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MyanmarCalendarProvider()) { entry in
            FullCalendarWidgetView(entry: entry)
        }
        .configurationDisplayName("Myanmar Calendar")
        .description("Shows the date, moon phase, holidays, and astrology details.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct MyanmarMonthWidgetView: View {
    let entry: MyanmarCalendarEntry
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 2), count: 7)

    var body: some View {
        if let month = entry.month {
            VStack(spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(month.myanmarYear) \(month.myanmarMonthName)")
                        .font(.headline)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Text("\(month.westernMonthName) \(month.westernYear)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                LazyVGrid(columns: columns, spacing: 3) {
                    ForEach(Array(entry.weekdayNames.enumerated()), id: \.offset) { _, name in
                        Text(String(name.prefix(3)))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(Array(month.days.prefix(42).enumerated()), id: \.offset) { _, day in
                        dayCell(day)
                    }
                }
            }
            .calendarWidgetBackground()
        } else {
            VStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.title)
                Text("Open Myanmar Calendar to prepare the month widget.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .calendarWidgetBackground()
        }
    }

    @ViewBuilder
    private func dayCell(_ day: MyanmarMonthDay) -> some View {
        let isToday = Calendar.autoupdatingCurrent.dateComponents(
            [.year, .month, .day],
            from: entry.date
        ) == DateComponents(
            year: day.westernYear,
            month: day.westernMonth,
            day: day.westernDay
        )

        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 5)
                .fill(isToday ? Color.green.opacity(0.22) : Color.clear)
            Text("\(day.westernDay)")
                .font(.system(size: 10, weight: isToday ? .bold : .regular))
                .foregroundColor(day.isCurrentMonth ? .primary : .secondary.opacity(0.55))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if day.hasHoliday {
                Circle()
                    .fill(Color.red)
                    .frame(width: 4, height: 4)
                    .padding(2)
            }
        }
        .frame(height: 17)
        .accessibilityLabel("\(day.westernDay)")
    }
}

struct MyanmarMonthWidget: Widget {
    let kind = "MyanmarMonthWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MyanmarCalendarProvider()) { entry in
            MyanmarMonthWidgetView(entry: entry)
        }
        .configurationDisplayName("Myanmar Month")
        .description("Shows the current Myanmar month as a calendar grid.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
