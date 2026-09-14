import SwiftUI
import UIKit
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
    let fortnightDayText: String
    let nextMoonPhase: String
    let moonPhaseImagePath: String
    let fullMoonPhaseImagePath: String
    let holidays: String
    let sabbathInfo: String
    let astrologicalDays: String
    let theme: String
    let showHolidays: Bool
    let showAstrology: Bool
    let showMyanmarDate: Bool
    let showWesternDate: Bool
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
            fortnightDayText: string(data, "fortnight_day_text"),
            nextMoonPhase: string(data, "next_moon_phase"),
            moonPhaseImagePath: string(data, "moon_phase_image_path"),
            fullMoonPhaseImagePath: string(data, "full_moon_phase_image_path"),
            holidays: string(data, "holidays"),
            sabbathInfo: string(data, "sabbath_info"),
            astrologicalDays: string(data, "astrological_days"),
            theme: defaults?.string(forKey: "widget_theme") ?? "auto",
            showHolidays: bool(forKey: "show_holidays", fallback: true),
            showAstrology: bool(forKey: "show_astrology", fallback: true),
            showMyanmarDate: bool(forKey: "show_myanmar_date", fallback: true),
            showWesternDate: bool(forKey: "show_western_date", fallback: true),
            month: monthSnapshot(for: dateKey, timeline: monthTimeline),
            weekdayNames: weekdayNames()
        )
    }

    private static func scalarData() -> [String: Any] {
        guard let defaults else { return [:] }
        let keys = [
            "western_date", "myanmar_date", "moon_phase",
            "moon_phase_emoji", "fortnight_day", "holidays",
            "fortnight_day_text", "next_moon_phase",
            "moon_phase_image_path", "full_moon_phase_image_path",
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

    private static func bool(forKey key: String, fallback: Bool) -> Bool {
        guard let defaults, defaults.object(forKey: key) != nil else {
            return fallback
        }
        return defaults.bool(forKey: key)
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
            fortnightDayText: "15 days",
            nextMoonPhase: "New Moon in 15d",
            moonPhaseImagePath: "",
            fullMoonPhaseImagePath: "",
            holidays: "",
            sabbathInfo: "",
            astrologicalDays: "",
            theme: "auto",
            showHolidays: true,
            showAstrology: true,
            showMyanmarDate: true,
            showWesternDate: true,
            month: nil,
            weekdayNames: ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        )
    }
}

private struct WidgetPalette {
    let background: [Color]
    let primary: Color
    let secondary: Color
    let accent: Color
    let highlight: Color
    let divider: Color

    static func resolve(theme: String, colorScheme: ColorScheme) -> WidgetPalette {
        switch theme {
        case "light":
            return light
        case "dark":
            return dark
        case "traditional":
            return WidgetPalette(
                background: [
                    Color(red: 0.82, green: 0.18, blue: 0.18),
                    Color(red: 0.72, green: 0.11, blue: 0.11),
                ],
                primary: Color(red: 0.98, green: 0.99, blue: 1.0),
                secondary: Color(red: 0.94, green: 0.89, blue: 0.82),
                accent: Color(red: 1.0, green: 0.85, blue: 0.44),
                highlight: Color(red: 1.0, green: 0.88, blue: 0.54),
                divider: Color.white.opacity(0.22)
            )
        case "gradientPurple":
            return darkGradient(
                [
                    Color(red: 0.37, green: 0.17, blue: 0.53),
                    Color(red: 0.29, green: 0.12, blue: 0.44),
                ]
            )
        case "gradientTeal":
            return darkGradient(
                [
                    Color(red: 0.04, green: 0.52, blue: 0.46),
                    Color(red: 0.03, green: 0.37, blue: 0.33),
                ]
            )
        case "gradientBlue":
            return blue
        default:
            return colorScheme == .dark ? dark : light
        }
    }

    private static let light = WidgetPalette(
        background: [
            Color(red: 0.99, green: 0.99, blue: 1.0),
            Color(red: 0.93, green: 0.95, blue: 0.97),
        ],
        primary: Color(red: 0.11, green: 0.14, blue: 0.19),
        secondary: Color(red: 0.34, green: 0.38, blue: 0.44),
        accent: Color(red: 0.18, green: 0.50, blue: 0.23),
        highlight: Color(red: 0.90, green: 0.35, blue: 0.0),
        divider: Color(red: 0.12, green: 0.18, blue: 0.24).opacity(0.15)
    )

    private static let dark = WidgetPalette(
        background: [
            Color(red: 0.12, green: 0.15, blue: 0.19),
            Color(red: 0.08, green: 0.11, blue: 0.14),
        ],
        primary: Color(red: 0.97, green: 0.98, blue: 1.0),
        secondary: Color(red: 0.79, green: 0.84, blue: 0.90),
        accent: Color(red: 1.0, green: 0.85, blue: 0.44),
        highlight: Color(red: 1.0, green: 0.88, blue: 0.54),
        divider: Color.white.opacity(0.18)
    )

    private static let blue = darkGradient(
        [
            Color(red: 0.11, green: 0.24, blue: 0.45),
            Color(red: 0.18, green: 0.39, blue: 0.66),
        ]
    )

    private static func darkGradient(_ colors: [Color]) -> WidgetPalette {
        WidgetPalette(
            background: colors,
            primary: Color(red: 0.97, green: 0.98, blue: 1.0),
            secondary: Color(red: 0.82, green: 0.88, blue: 0.95),
            accent: Color(red: 1.0, green: 0.85, blue: 0.44),
            highlight: Color(red: 1.0, green: 0.88, blue: 0.54),
            divider: Color.white.opacity(0.18)
        )
    }
}

private struct CalendarWidgetBackground: View {
    let palette: WidgetPalette

    var body: some View {
        LinearGradient(
            colors: palette.background,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

private extension View {
    @ViewBuilder
    func calendarWidgetBackground(_ palette: WidgetPalette) -> some View {
        if #available(iOS 17.0, *) {
            containerBackground(for: .widget) {
                CalendarWidgetBackground(palette: palette)
            }
        } else {
            background(CalendarWidgetBackground(palette: palette))
        }
    }
}

private extension MyanmarCalendarEntry {
    var westernParts: (day: String, month: String, year: String) {
        let parts = westernDate.split(separator: " ").map(String.init)
        return (
            parts.indices.contains(0) ? parts[0] : "--",
            parts.indices.contains(1) ? parts[1] : "",
            parts.indices.contains(2) ? parts[2] : ""
        )
    }

    var compactMyanmarDate: String {
        let parts = myanmarDate.split(separator: " ").map(String.init)
        guard parts.count > 3 else { return myanmarDate }
        return parts.dropFirst().joined(separator: " ")
    }
}

private struct MoonArtwork: View {
    let path: String
    let fallback: String
    let size: CGFloat

    var body: some View {
        Group {
            if !path.isEmpty, let image = UIImage(contentsOfFile: path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
            } else {
                Text(fallback)
                    .font(.system(size: size * 0.72))
            }
        }
        .frame(width: size, height: size)
    }
}

struct CompactDateWidgetView: View {
    let entry: MyanmarCalendarEntry
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let palette = WidgetPalette.resolve(theme: entry.theme, colorScheme: colorScheme)
        let date = entry.westernParts

        Group {
            if family == .systemSmall {
                VStack(alignment: .leading, spacing: 7) {
                    if entry.showWesternDate {
                        HStack(alignment: .firstTextBaseline, spacing: 5) {
                            Text(date.day)
                                .font(.system(size: 34, weight: .semibold, design: .rounded))
                            Text(date.month)
                                .font(.caption.weight(.semibold))
                                .foregroundColor(palette.secondary)
                                .lineLimit(1)
                        }
                    }
                    if entry.showMyanmarDate {
                        Text(entry.myanmarDate)
                            .font(.system(size: 14, weight: .semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                    }
                    Spacer(minLength: 0)
                    HStack(spacing: 5) {
                        Text(entry.moonPhaseEmoji)
                        Text(entry.moonPhase)
                            .font(.caption2.weight(.medium))
                            .foregroundColor(palette.secondary)
                            .lineLimit(1)
                        Spacer(minLength: 0)
                        Circle()
                            .fill(palette.accent)
                            .frame(width: 7, height: 7)
                    }
                }
            } else {
                HStack(spacing: 12) {
                    if entry.showWesternDate {
                        HStack(alignment: .lastTextBaseline, spacing: 5) {
                            Text(date.day)
                                .font(.system(size: 32, weight: .semibold, design: .rounded))
                            VStack(alignment: .leading, spacing: 0) {
                                Text(date.month)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                Text(date.year)
                                    .font(.caption2)
                                    .foregroundColor(palette.secondary)
                            }
                        }
                        Rectangle()
                            .fill(palette.divider)
                            .frame(width: 1, height: 34)
                    }
                    if entry.showMyanmarDate {
                        Text(entry.myanmarDate)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.72)
                    }
                    Spacer(minLength: 0)
                    Circle()
                        .fill(palette.accent)
                        .frame(width: 8, height: 8)
                }
            }
        }
        .foregroundColor(palette.primary)
        .calendarWidgetBackground(palette)
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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let palette = WidgetPalette.resolve(theme: entry.theme, colorScheme: colorScheme)
        let artworkSize: CGFloat = family == .systemSmall ? 68 : 78

        VStack(spacing: family == .systemSmall ? 5 : 7) {
            if entry.showMyanmarDate {
                Text(entry.compactMyanmarDate)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(palette.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            MoonArtwork(
                path: entry.fullMoonPhaseImagePath,
                fallback: entry.moonPhaseEmoji,
                size: artworkSize
            )
            Text(entry.moonPhase)
                .font(.headline.weight(.semibold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            if !entry.fortnightDayText.isEmpty {
                Text(entry.fortnightDayText)
                    .font(.caption2)
                    .foregroundColor(palette.secondary)
                    .lineLimit(1)
            }
            if family != .systemSmall, !entry.nextMoonPhase.isEmpty {
                Text(entry.nextMoonPhase)
                    .font(.caption2.weight(.medium))
                    .foregroundColor(palette.accent)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .foregroundColor(palette.primary)
        .calendarWidgetBackground(palette)
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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) private var family

    var body: some View {
        let palette = WidgetPalette.resolve(theme: entry.theme, colorScheme: colorScheme)
        let date = entry.westernParts

        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Image(systemName: "calendar")
                Text("Myanmar Calendar")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("TODAY")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(red: 0.10, green: 0.15, blue: 0.22))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(palette.accent, in: Capsule())
            }
            .foregroundColor(palette.secondary)

            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 5) {
                    if entry.showWesternDate {
                        HStack(alignment: .lastTextBaseline, spacing: 7) {
                            Text(date.day)
                                .font(.system(size: 36, weight: .semibold, design: .rounded))
                            VStack(alignment: .leading, spacing: 0) {
                                Text(date.month)
                                    .font(.caption.weight(.semibold))
                                Text(date.year)
                                    .font(.caption2)
                                    .foregroundColor(palette.secondary)
                            }
                        }
                    }
                    Rectangle()
                        .fill(palette.divider)
                        .frame(height: 1)
                    if entry.showMyanmarDate {
                        Text(entry.myanmarDate)
                            .font(.system(size: 15, weight: .semibold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                    }
                    if entry.showHolidays, !entry.holidays.isEmpty {
                        Text("🎉 \(entry.holidays)")
                            .font(.caption2.weight(.medium))
                            .foregroundColor(palette.highlight)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 3) {
                    MoonArtwork(
                        path: entry.fullMoonPhaseImagePath,
                        fallback: entry.moonPhaseEmoji,
                        size: family == .systemLarge ? 94 : 68
                    )
                    Text(entry.moonPhase)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(palette.accent)
                        .lineLimit(1)
                    if !entry.fortnightDayText.isEmpty {
                        Text(entry.fortnightDayText)
                            .font(.caption2)
                            .foregroundColor(palette.secondary)
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: family == .systemLarge ? 130 : 105)
            }

            if family == .systemLarge,
               entry.showAstrology,
               (!entry.sabbathInfo.isEmpty || !entry.astrologicalDays.isEmpty) {
                let details = [entry.sabbathInfo, entry.astrologicalDays]
                    .filter { !$0.isEmpty }
                    .joined(separator: " • ")
                Label(details, systemImage: "sparkles")
                    .font(.caption2)
                    .foregroundColor(palette.secondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 0)
        }
        .foregroundColor(palette.primary)
        .calendarWidgetBackground(palette)
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
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let palette = WidgetPalette.resolve(theme: entry.theme, colorScheme: colorScheme)

        if let month = entry.month {
            VStack(spacing: 5) {
                HStack(alignment: .firstTextBaseline) {
                    Text("\(month.myanmarYear) \(month.myanmarMonthName)")
                        .font(.headline)
                        .minimumScaleFactor(0.7)
                    Spacer()
                    Text("\(month.westernMonthName) \(month.westernYear)")
                        .font(.caption2)
                        .foregroundColor(palette.secondary)
                }

                LazyVGrid(columns: columns, spacing: 3) {
                    ForEach(Array(entry.weekdayNames.enumerated()), id: \.offset) { _, name in
                        Text(String(name.prefix(3)))
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(palette.secondary)
                            .frame(maxWidth: .infinity)
                    }

                    ForEach(Array(month.days.prefix(42).enumerated()), id: \.offset) { _, day in
                        dayCell(day, palette: palette)
                    }
                }
            }
            .foregroundColor(palette.primary)
            .calendarWidgetBackground(palette)
        } else {
            VStack(spacing: 8) {
                Image(systemName: "calendar")
                    .font(.title)
                Text("Open Myanmar Calendar to prepare the month widget.")
                    .font(.caption)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .foregroundColor(palette.primary)
            .calendarWidgetBackground(palette)
        }
    }

    @ViewBuilder
    private func dayCell(_ day: MyanmarMonthDay, palette: WidgetPalette) -> some View {
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
                .fill(isToday ? palette.accent.opacity(0.30) : Color.clear)
            Text("\(day.westernDay)")
                .font(.system(size: 10, weight: isToday ? .bold : .regular))
                .foregroundColor(
                    day.isCurrentMonth ? palette.primary : palette.secondary.opacity(0.55)
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            if day.hasHoliday {
                Circle()
                    .fill(palette.highlight)
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
