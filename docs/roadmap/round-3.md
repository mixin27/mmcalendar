# Round 3 (release 2.7.0)

Six features picked after 2.6.0. Each is its own PR with English and Myanmar strings and tests, `scripts/test_all.sh` and `scripts/analyze_all.sh` passing, and a web check at 390 px in both languages. Native work also gets `flutter build apk` / `flutter build ios --simulator` and a simulator or emulator run where it can.

| # | Feature | Size | Status |
|---|---|---|---|
| 1 | Long-weekend planner | S–M | Done, #79 |
| 2 | Merit diary | M | Done, #81 |
| 3 | Share events by QR / link | M | Done, #82 |
| 4 | Ask the calendar (AI) | M–L | On hold: needs its own plan |
| 5 | Interactive widgets | M–L | In progress |
| 6 | Watch app | L | Done, #83 (Apple Watch), #84 (Wear OS) |

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

## 5. Interactive widgets: in progress
- **Already there:** previous/next month buttons on both platforms (iOS `ChangeMonthIntent`, Android `ChangeMonthAction`).
- **Tick an event done:** a tick circle starts every event row: the shared `EventRow`, in the Agenda and Today widgets. The rest of the row still opens the event.
  - The widget's own code (an iOS App Intent, an Android Glance `ActionCallback`) flips `done` in the saved payload, so the widget redraws at once, and adds `{id, day, recurring, done}` to a queue (`widget_actions_v1`) in the same storage.
  - The app applies the queue when it starts or comes back, through `EventMarkersPort.toggleEventCompletion`: a recurring event is completed for that one day, as in day details. The widget sync then rebuilds the payload.
  - A background refresh that draws from the cached events applies the queue too, so a tick isn't undone before the app opens.
  - Chosen over home_widget's Dart background callback: that would link Flutter into the iOS widget extension and start a Flutter engine per tap, and the background refresh doesn't open the database today.
  - Limit: the database catches up when the app next opens or resumes.
- **Today's note:** "Add a note" opens day details with the note editor already open (`mmcalendar://day/<date>?note=1`).
- Needs a real-device check before release.

## 6. Watch app (done, #83 and #84)
Two PRs:
- **Apple Watch:** a SwiftUI watchOS app and WidgetKit complications in this repo. They draw the same 180-day `widget_data_v2` payload as the iPhone widgets, sent over WatchConnectivity, and share the widgets' Swift code.
- **Wear OS:** the separate `myanmar_calendar_wear` Flutter app (never released) moves into `apps/myanmar_calendar_wear`, on `myanmar_calendar_dart` 3.x and the shared holidays and payload code, with a Kotlin Tile and complication.
- Your part: bundle ids, App Group and screenshots in App Store Connect; the Wear form factor in Play Console; archiving the old repo.
