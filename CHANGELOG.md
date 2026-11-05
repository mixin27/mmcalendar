## [2.5.0+250] - 2026-11-05

- Day notes: write a note on any day from the home sheet or day details. Days with a note get a dot in every grid style, and Views › Notes lists and searches them all.
- Search (the search button on Home): dates typed in English or Myanmar ("13 Apr 2027", "Tabaung full moon 1388", "တန်ခူးလဆန်း ၅", "next Sabbath"), plus holidays, events and notes.
- Sabbath reminders: the evening before or the morning of every Sabbath day, from Holidays › Reminders or a Sabbath's day details.
- Views › Good days: the days with good astrological marks in the next 1, 3 or 6 months, optionally by weekday.
- Converter › Birth: the birth sign (with Wednesday before or after noon), Mahabote, Nakhat, exact age, and the next Western and Myanmar birthdays.
- Settings › Privacy & Data › Backup and restore: back up events, notes, custom holidays and reminder choices to one file and restore them (merge or replace); export events as an .ics file for Google or Apple Calendar.
- Fixed the Astrology widget, which showed Yatyaza as a day to avoid and Thamanyo as good; it now matches day details.

## [2.4.0+240] - 2026-11-05

- Festivals explained: tap a holiday on the calendar, or open it from a reminder, to read what it marks. Every holiday page now has Good to know: what happens, practical tips, etiquette and where to see it, in English and Myanmar.
- Settings › Display Preferences: "English for Western Dates" shows Western months and numbers in English (October 2026) in the app and in home-screen widgets, whatever the calendar language.
- Holidays: New Year's Day (1 January) is a public holiday again from 2025, and Chinese New Year is a public holiday from 2025. Corrected the explanations for New Year's Day, New Year's Eve, Garudhamma Day and Mon National Day.
- Calendar Studio: changing the year of an imported design (.mmcstudio or .mmctemplate) no longer piles preset elements on top of it, and imported designs keep their colours.
- Calendar Studio: designs with empty photo frames can be exported; each empty frame prints as a thin outline, for a photo you add by hand.

## [2.3.1+232] - 2026-10-27

- Fixed photos missing from Calendar Studio exports: PDF, PNG and JPEG pages showed empty photo frames.
- Fixed template legends (such as Jade wall) that were hard to read with a dark app theme and showed boxes instead of Myanmar words in exports.
- Web: Calendar Studio exports PDF, JPEG and ZIP again, adds photos again (also large ones; they're now kept in the browser's IndexedDB), and includes them in exports.
- Web: a new Vector PDF export keeps text, shapes and photos editable in Illustrator; Myanmar text is placed as sharp images.
- Calendar Studio's action buttons are full height on desktop.

## [2.3.0+231] - 2026-10-21

- Fixed a crash on launch on iOS 27 and iPadOS 27 (home-screen widget data cleanup wrote null to UserDefaults).
- Calendar Studio replaces Calendar Generation: design wall, desk, social and story calendars from presets, edit on the page, re-theme every page, and export PDF, PNG, JPEG or ZIP at each page's real paper size (with page-size presets).
- Home calendar: 22 grid layouts with Almanac as the new default (saved choices are kept), twelve grid themes, and Clear and Material app styles.
- Day details: astrology in plain words (Sabbath, Yatyaza, Pyatthada, Mahabote, Nakhat, year name, Nagahle) as chips.
- Holidays page with search, filters, details and reminders.
- Events: weekly class timetables with a time for each day, and one event on several chosen dates.
- Home-screen widgets rebuilt in five styles on iOS (with lock-screen widgets) and Android (Jetpack Glance).
- Custom colours page: one accent colour, or every colour in Advanced.
- New Moon page app icon with iOS dark and tinted versions and an Android themed icon; ten icons in Settings › App icon.
- Onboarding with a short tour and quick setup, and a What's new sheet after each update.

## [2.2.1+221] - 2026-03-04

- Refreshed brand assets and launcher icons:
  - New night-sky visual direction with glowing full-moon style.
  - Updated Play Store feature graphic output.
  - Regenerated Android, iOS/macOS, and web icon assets from branding generator.
- Expanded selectable app icon variants in settings:
  - Default
  - Moon
  - Forest
  - Minimal Flat
  - Premium Dark
  - Traditional Myanmar
- Improved dynamic app-icon switching behavior:
  - Added stronger iOS switching guards and retry handling for transient LaunchServices failures (`NSPOSIXErrorDomain code=35`).
  - Improved method-channel flow for icon selection and state synchronization.
  - Added alternate icon metadata compatibility fallback in iOS `Info.plist`.
- Added native setup recovery tooling for maintainability:
  - `scripts/restore_native_mobile_setup.sh` to restore Android icons/widgets and iOS icon setup from git.
  - `scripts/verify_native_mobile_setup.sh` to verify native integration contracts.
  - Added architecture documentation: `docs/architecture/native_mobile_setup.md`.
- Fixed first-launch calendar language inconsistency:
  - Unified fallback defaults so calendar runtime, settings page, reset flow, and home-widget background updates all use Myanmar (`my`) by default.
- Important platform note:
  - iOS Simulator may not reliably support alternate icon switching (known LaunchServices limitation).
  - Validate icon switching on a physical iOS device or cloud real-device environment.

## [2.2.0+220] - 2026-03-02

- Migrated core Myanmar calendar logic and app configuration to `myanmar_calendar_dart` APIs.
- Updated Myanmar calendar settings flow for newer core config behavior (formatting/configuration/translation support alignment).
- Improved custom holiday support flow and remote-config driven holiday handling.
- Added calendar generation/export improvements:
  - Better preview/export consistency and positioning behavior.
  - Calendar layout controls (position/size) and free-space box controls.
  - Dedicated full-screen Layout Editor with larger transform handles.
  - Overlay editor workflow refinements and export save/share actions.
- Improved generated calendar cell details (holiday/astrology/moon-phase related rendering refinements).
- Fixed multiple generation preview/editor issues:
  - Provider and controller lifecycle errors in editor flows.
  - Preview clipping/overflow issues in portrait/landscape modes.
  - Rotation/position mismatch and persistence edge cases.
  - Free-space box persistence after restart.
- General UI polish for generation settings, bottom-sheet grouping, and preview interaction.

> Note: Calendar Generation is still in preview/beta quality and is not fully production-grade yet.

## [2.1.6+216] - 2026-02-27

- Events UX refresh: redesigned day-based event list items with timeline style and quicker actions.
- Day Details events section redesigned with cleaner list items and improved readability.
- Event form polished with consistent section cards and clearer structure.
- Event categories page polished for cleaner management flow.
- Fixed recurring event completion to update only the selected occurrence (not the whole series).
- Fixed recurring event detail to open the correct past/selected occurrence.
- Fixed completed event detail opening issue (`Event not found`) in event detail flow.
- Fixed selected-date row indicators not updating correctly after editing event date.
- Simplified event list app bar actions by removing unnecessary debug/overflow actions.

## [2.1.5+209]

- Fixed home widget background update issue
- Custom holidays & disabled holidays via Remote Config
- Remove old legacy android home widget
- Fixed day of week miss-match in calculator date selector fields
- Fixed enable firebase service on web

## [2.1.4+208]

- Add promo carousel feature for introducing new features
- Settings page and components restyled
- Fixed event list view show all the recurring events between the default date range
- Fixed event indicator rendering issue in date cell
- Fixed platform error issue in settings page for web platform

## [2.1.3+207] - 2026-01-08

### ✨ Added
- **Past Event Support**: Enabled creating and viewing events for dates prior to today.
- **Improved Sharing**: Switched to native sharing for better reliability across platforms.
- **Telegram Integration**: Added Telegram sharing to the Day Details page and fixed web app compatibility issues.

### 🐛 Fixed
- Fixed a bug where events for past dates were not visible in the lists.
- Resolved web navigation errors and build issues.
- Improved app shell responsiveness for web and desktop.

---

## [2.0.0] - 2025-10-15

### 🎉 Initial Release

**The complete Myanmar Calendar experience for mobile devices!**

### ✨ Added

#### Calendar Features
- **Month View**: Full calendar grid with Myanmar and Western dates
- **Year View**: 12-month overview with quick navigation
- **Week View**: Detailed 7-day view
- **Day View**: Comprehensive single-day information
- **Day Details Page**: In-depth information for selected dates

#### Myanmar Calendar System
- Accurate Myanmar date calculations
- Buddhist Era (BE) year display
- Sasana Year calculations
- Moon phase tracking
- Fortnight day (လဆန်း/လဆုတ်) information
- Watat year (ဝါထပ်နှစ်) identification
- Traditional Myanmar weekday system

#### Astrological Information
- Sabbath days (ဉပုသ်ရက်)
- Yatyaza (ရက်ရာဇာ) calculations
- Pyathada (ပြဿဒါး) information
- Nagahle (နဂါးခေါင်း) direction
- Mahabote (မဟာဘုတ်) astrology
- Nakhat (နက္ခတ်) details
- 12-year cycle animal names
- Special astrological days

#### Holidays & Special Days
- Myanmar public holidays
- Buddhist religious holidays
- Traditional festivals
- Cultural celebrations

#### Date Converter Tools
- Western ↔ Myanmar date conversion
- Date difference calculator
- Date arithmetic (add/subtract days/months)
- Moon phase finder
- Julian Day Number support
- Real-time conversion

#### Themes & Customization
- Light and Dark themes
- Theme presets:
  - Modern (Default)
  - Traditional Myanmar
  - Ocean Blue
  - Forest Green
- Custom color picker
- Personalized theme creation
- Smooth theme transitions

#### Language Support
- မြန်မာဘာသာ (Myanmar Unicode)
- Zawgyi (ဇော်ဂျီ)
- English
- Mon (မွန်)
- Shan (ရှမ်း)
- Karen (ကရင်)

#### User Experience
- Beautiful Material Design 3 UI
- Smooth animations and transitions
- Haptic feedback
- Intuitive navigation
- Bottom navigation bar
- Fast and responsive performance
- 100% offline functionality

#### Settings
- Language preferences
- Theme customization
- Calendar configuration
- Display preferences
- About app information

### Native
- Home screen widgets (Android)

### 🏗️ Technical

#### Architecture
- Clean Architecture implementation
- BLoC pattern for state management
- Modular feature-based structure
- Event Bus for cross-feature communication

#### Tech Stack
- Flutter 3.0+
- Dart 3.0+
- flutter_bloc for state management
- go_router for navigation
- drift for local database
- get_it + injectable for dependency injection
- flutter_mmcalendar package for calendar calculations

#### Performance
- Optimized rendering
- Efficient database queries
- Minimal memory footprint
- Fast app startup
- Smooth 60fps animations

#### Quality
- Comprehensive error handling
- Input validation
- Null safety
- Code documentation
- Unit tests for core logic

### 📱 Platform Support
- Android 5.0 (API 21) and above
- iOS 12.0 and above
- Phone and tablet support
- Portrait and landscape orientations

### 🔒 Privacy & Security
- Zero data collection
- No internet permission required
- All data stored locally
- No third-party analytics
- No advertisements
- Privacy-first design
