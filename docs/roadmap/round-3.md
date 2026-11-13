# Round 3 (release 2.7.0)

Six features picked after 2.6.0. Each is its own PR with English and Myanmar strings and tests, `scripts/test_all.sh` and `scripts/analyze_all.sh` passing, and a web check at 390 px in both languages. Native work also gets `flutter build apk` / `flutter build ios --simulator` and a simulator or emulator run where it can.

| # | Feature | Size | Status |
|---|---|---|---|
| 1 | Long-weekend planner | S–M | Done, #79 |
| 2 | Merit diary | M | Done, #81 |
| 3 | Share events by QR / link | M | Done, #82 |
| 4 | Ask the calendar (AI) | M–L | On hold: needs its own plan |
| 5 | Interactive widgets | M–L | To do |
| 6 | Watch app | L | In progress: Apple Watch, then Wear OS |

Then: release 2.7.0 (CHANGELOG, What's new cards, store text, tag and GitHub release).

---

## 1. Long-weekend planner (done, #79)
- `LongWeekends.plan(year, {leaveDays: 1–3})` in `holidays/lib/src/domain/`: office-closed holidays plus weekends, best leave days ranked by days gained per leave day; future only.
- Holidays page card and a list page (`/views/holidays/long-weekends`) with a 1/2/3 leave-days choice and Share.

## 2. Merit diary (done, #81)
- `merit_entries` table: day, kind (donation, precepts, meditation, other), note, optional amount.
- A Merit row in day details and the home sheet; Views › Merit diary with a monthly list, a yearly summary and a Sabbath streak; an optional Sabbath-morning nudge; included in backups.

## 3. Share events by QR or link (done, #82)
- Event details › Share: a QR code, an `mmcalendar://add-event` link, or an `.ics` file.
- Opening the link previews the event (Myanmar repeats included) with "Add to my calendar".
- Shipped as base64url JSON rather than the `.ics` VEVENT first planned: shorter in a QR code and carries Myanmar repeats as they are.

## 4. Ask the calendar (AI): on hold
First idea, kept for the dedicated plan:
- Search page "Ask", behind a Remote Config flag (off by default, like Studio's AI).
- Firebase AI (Gemini), as Calendar Studio uses; the model reads the question and the app answers with its own calendar code (date conversion, holidays, good days, long weekends, moon phases).
- Only calendar facts are sent, never the user's events, notes or merit entries.
- Still open: what it should answer, whether it can read or create events, and whether the model or the app writes the answer.

## 5. Interactive widgets: to do
- `home_widget` interactivity with Dart background callbacks: iOS 17+ AppIntent buttons, Android Glance `actionRunCallback`.
- Agenda / Coming up: tick an event done. Month widget: previous/next month on iOS. Today's note: "Add" opens the editor.
- Needs a real-device check before release.

## 6. Watch app: in progress
Two PRs:
- **Apple Watch:** a SwiftUI watchOS app and WidgetKit complications in this repo. They draw the same 180-day `widget_data_v2` payload as the iPhone widgets, sent over WatchConnectivity, and share the widgets' Swift code.
- **Wear OS:** the separate `myanmar_calendar_wear` Flutter app (never released) moves into `apps/myanmar_calendar_wear`, on `myanmar_calendar_dart` 3.x and the shared holidays and payload code, with a Kotlin Tile and complication.
- Your part: bundle ids, App Group and screenshots in App Store Connect; the Wear form factor in Play Console; archiving the old repo.
