import SwiftUI
import WidgetKit

@main
struct MyanmarCalendarWidgetsBundle: WidgetBundle {
    var body: some Widget {
        HomeScreenWidgets().body
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

struct LockScreenWidgets: WidgetBundle {
    var body: some Widget {
        LockScreenMoonWidget()
        LockScreenDayWidget()
        LockScreenDateWidget()
        LockScreenLineWidget()
    }
}
