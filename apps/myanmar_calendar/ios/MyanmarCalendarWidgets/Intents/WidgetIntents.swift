import AppIntents
import WidgetKit

/// The style a single widget wears; `standard` follows Settings › Widgets.
enum StyleOption: String, AppEnum {
    case standard, app, plain, pagoda, jade, deepField

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Style"
    static var caseDisplayRepresentations: [StyleOption: DisplayRepresentation] = [
        .standard: "Default",
        .app: "Follow app",
        .plain: "Plain",
        .pagoda: "Pagoda",
        .jade: "Jade",
        .deepField: "Deep Field",
    ]

    /// The style name to draw with, given the app's default.
    func resolved(default fallback: String) -> String {
        self == .standard ? fallback : rawValue
    }
}

enum CountdownOption: String, AppEnum {
    case standard, fullMoon, newMoon, sabbath, thingyan

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Count down to"
    static var caseDisplayRepresentations: [CountdownOption: DisplayRepresentation] = [
        .standard: "Default",
        .fullMoon: "Next full moon",
        .newMoon: "Next new moon",
        .sabbath: "Next Sabbath",
        .thingyan: "Thingyan",
    ]
}

/// Widgets whose only setting is their style.
protocol StyledIntent: WidgetConfigurationIntent {
    var style: StyleOption { get }
}

struct StyleIntent: StyledIntent {
    static var title: LocalizedStringResource = "Widget"
    static var description = IntentDescription("Choose how this widget looks.")

    @Parameter(title: "Style", default: .standard)
    var style: StyleOption

    init() {}
}

struct CountdownIntent: StyledIntent {
    static var title: LocalizedStringResource = "Countdown"
    static var description = IntentDescription("Choose what this widget counts down to.")

    @Parameter(title: "Count down to", default: .standard)
    var target: CountdownOption

    @Parameter(title: "Style", default: .standard)
    var style: StyleOption

    init() {}
}

// MARK: - Month buttons

/// How many months the Month widgets are moved from today's month. Shared by
/// all Month widgets and reset each day.
enum MonthOffset {
    private static let offsetKey = "widget_month_offset"
    private static let dayKey = "widget_month_offset_day"

    static func current(on date: Date = .now) -> Int {
        let defaults = UserDefaults(suiteName: PayloadStore.appGroup)
        guard defaults?.string(forKey: dayKey) == DayKey.string(date) else { return 0 }
        return defaults?.integer(forKey: offsetKey) ?? 0
    }

    static func move(by delta: Int) {
        let defaults = UserDefaults(suiteName: PayloadStore.appGroup)
        // The payload holds last month to five months ahead.
        let next = min(max(current() + delta, -1), 5)
        defaults?.set(next, forKey: offsetKey)
        defaults?.set(DayKey.string(.now), forKey: dayKey)
    }
}

struct ChangeMonthIntent: AppIntent {
    static var title: LocalizedStringResource = "Change month"
    static var isDiscoverable = false

    @Parameter(title: "Months")
    var delta: Int

    init() {}
    init(delta: Int) { self.delta = delta }

    func perform() async throws -> some IntentResult {
        MonthOffset.move(by: delta)
        return .result()
    }
}

// MARK: - Timeline

struct PayloadEntry: TimelineEntry {
    let date: Date
    let payload: WidgetPayload?
    let styleName: String
    var countdown: CountdownOption = .standard

    var day: WidgetPayload.Day? { payload?.day(for: date) }
}

/// One entry per day at midnight, from today until the payload ends (at
/// most 60), so the date rolls over without the app running.
struct PayloadProvider<Intent: StyledIntent>: AppIntentTimelineProvider {
    var countdown: (Intent) -> CountdownOption = { _ in .standard }

    func placeholder(in context: Context) -> PayloadEntry {
        PayloadEntry(date: .now, payload: PayloadStore.load(), styleName: "app")
    }

    func snapshot(for configuration: Intent, in context: Context) async -> PayloadEntry {
        entry(at: .now, configuration: configuration, payload: PayloadStore.load())
    }

    func timeline(for configuration: Intent, in context: Context) async -> Timeline<PayloadEntry> {
        let payload = PayloadStore.load()
        let today = Calendar.current.startOfDay(for: .now)
        var entries = [entry(at: .now, configuration: configuration, payload: payload)]
        let available = payload?.days.count ?? 1
        for offset in 1..<min(60, max(available, 2)) {
            if let next = Calendar.current.date(byAdding: .day, value: offset, to: today) {
                entries.append(entry(at: next, configuration: configuration, payload: payload))
            }
        }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func entry(at date: Date, configuration: Intent, payload: WidgetPayload?) -> PayloadEntry {
        PayloadEntry(
            date: date,
            payload: payload,
            styleName: configuration.style.resolved(default: payload?.prefs.style ?? "app"),
            countdown: countdown(configuration)
        )
    }
}
