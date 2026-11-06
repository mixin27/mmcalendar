import SwiftUI
import WidgetKit

@main
struct MyanmarCalendarWidgetsBundle: WidgetBundle {
    var body: some Widget {
        HomeScreenWidgets().body
        MoreHomeScreenWidgets().body
        LockScreenWidgets().body
    }
}

struct HomeScreenWidgets: WidgetBundle {
    var body: some Widget {
        TodayWidget()
        MoonWidget()
        MonthWidget()
        WeekWidget()
        ComingUpWidget()
        AgendaWidget()
        CountdownWidget()
        AstrologyWidget()
        YearWidget()
    }
}

/// A bundle body takes at most ten widgets.
struct MoreHomeScreenWidgets: WidgetBundle {
    var body: some Widget {
        NoteWidget()
        GoodDaysWidget()
    }
}

struct LockScreenWidgets: WidgetBundle {
    var body: some Widget {
        LockScreenMoonWidget()
        LockScreenDayWidget()
        LockScreenDateWidget()
        LockScreenLineWidget()
    }
}
