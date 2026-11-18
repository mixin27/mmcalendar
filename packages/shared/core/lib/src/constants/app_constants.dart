class AppConstants {
  // App Information
  static const String appName = 'Myanmar Calendar';

  // Spacing and sizing
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Database
  static const String databaseName = 'myanmar_calendar.db';
  static const int databaseVersion = 1;

  // Date Formats
  static const String dateFormatFull = 'EEEE, MMMM d, yyyy';
  static const String dateFormatShort = 'MMM d, yyyy';
  static const String dateFormatNumeric = 'dd/MM/yyyy';

  // Calendar
  static const int calendarMonthsToPreload = 1;
  static const int calendarMaxYearRange = 100;

  // UI
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  static const double defaultElevation = 2.0;

  // Animation
  static const Duration animationDuration = Duration(milliseconds: 300);
  static const Duration shortAnimationDuration = Duration(milliseconds: 150);
  static const Duration mediumAnimationDuration = Duration(milliseconds: 400);
  static const Duration longAnimationDuration = Duration(milliseconds: 500);

  // Cache
  static const int maxCacheSize = 100;
  static const Duration cacheExpiration = Duration(hours: 24);

  static const String privacyPolicyMarkdown = '''
# Privacy Policy

**Last updated: 18 November 2026** · Applies to Myanmar Calendar 2.7 and later on Android, iOS, Apple Watch, Wear OS and the web.

Myanmar Calendar ("the app", "we") is made by Kyaw Zayar Tun. This policy explains what the app keeps on your device, what it sends and to whom, and the choices you have. In short: your events, notes and merit diary stay on your device unless you share them yourself; analytics and crash reports are off until you turn them on; there are no ads and we never sell data.

---

## 1. What stays on your device

The app stores the following in a database on your device (in the browser's storage for the web app):

- Your events: titles, dates and times, notes, locations, categories, repeats, reminders and whether they are done
- Day notes and merit diary entries
- Custom holidays and reminder choices (Sabbath reminders, holiday reminders, the daily summary)
- Calendar Studio projects, templates and the photos you add to them
- Your settings: languages, theme, layout, widget styles and the like

We have no servers that receive this data, and we cannot see it. The app does not add its own encryption to this database; it is protected by your device's security (screen lock and app sandbox). Deleting an event or note removes it; uninstalling the app removes everything it stored.

### Widgets and watches

- **Home-screen and lock-screen widgets** show a summary that the app saves in its own storage on your device: calendar days, holidays, the next two weeks of event titles and times, and short previews of day notes. Anyone who can see your home or lock screen can see what the widgets show. Ticking an event done on a widget is saved the same way and applied the next time you open the app.
- **Apple Watch:** the iPhone app sends the same summary to your paired Apple Watch through Apple's WatchConnectivity. It goes from your phone to your watch only.
- **Wear OS:** the Wear OS app runs on its own. It has no internet permission and holds only calendar data (dates, moon, holidays, Sabbath and astrology), with no events or notes.

### Notifications

Event reminders, Sabbath and holiday reminders and the daily summary are local notifications scheduled on your device. They work offline and nothing about them is sent to us. The app asks for notification permission during setup; you can turn it off in your device settings at any time.

---

## 2. What you choose to share

Some features send data only when you use them, and only where you send it:

- **Backup** (Settings › Privacy & Data › Backup and restore) makes one file with your events, reminders, repeats, categories, custom holidays, day notes, merit entries and reminder choices. The file is not encrypted. It goes wherever you save or send it (for example Files, Google Drive or iCloud), and anyone with the file can read it.
- **.ics export and import** move events to and from other calendar apps, using files you pick.
- **Sharing an event** creates a link, a QR code or an .ics file that contains the event's title, date, time, notes, location, category name and repeat. Anyone you give it to can read those details. The link opens in Myanmar Calendar; it is not stored on any server.
- **Sharing a day** creates an image or text of the date, Myanmar date, moon, holidays and astrology. It contains no events or notes.
- **The AI prompt** in day details builds text on your device for you to copy or share into an AI app of your choice. The app itself sends nothing.

---

## 3. Analytics and crash reports (off until you turn them on)

We use **Google Firebase Analytics** and **Firebase Crashlytics** to see which features are used and to fix crashes. Both are **off** when you install the app. You can turn each one on or off during setup or at any time in **Settings › Privacy & Data**. Collection only happens in release versions of the app.

**When Analytics is on**, it records:

- Which screens you open and which buttons and settings you use (for example "changed the theme" or "opened the converter")
- The calendar date being viewed or shared, and the app's internal number for an event you open
- Error messages from the app
- Information Firebase collects automatically: an app instance ID, device model, operating system, app version, language, session times and approximate location from your IP address (city or country level, not GPS)

**It never records** event titles, notes, descriptions or locations, merit entries, day notes or anything you type into the app.

**When crash reports are on**, Crashlytics receives crash details: the error and stack trace, device model, operating system, app version and the app's state at the time. Error messages can contain technical details about what failed.

On Android, the Firebase Analytics library can read your device's advertising ID while Analytics is on. We do not use it for advertising and the app shows no ads. You can reset or delete your advertising ID in your device settings.

Firebase keeps Analytics data for up to 14 months and crash reports for about 90 days. No name, email address or phone number is attached to it.

---

## 4. Services the app always uses

These run whatever your analytics choice, because the app needs them to work properly:

- **Firebase Remote Config** downloads updates to the holiday list, notices about new app versions and on/off switches for features, so they can change without an app update. To do this, the app sends Google a Firebase installation ID, the app version, the platform and your device's language and country settings.
- **Firebase App Check** asks Google Play Integrity (Android) or Apple App Attest (iOS) to confirm that requests come from the genuine app. This involves a device attestation token, not your personal information.

When you are offline, the calendar, events, notes, reminders and widgets keep working; only these updates wait until you are back online.

---

## 5. Calendar Studio "Suggest text" (AI)

When this feature is available and you tap **Suggest text**, the app sends a request to **Google's Gemini models through Firebase AI Logic**. The request contains:

- The kind of text you want (for example a title or a caption), the language, the year and month, and the page name
- The name of the template or design you are working on
- That month's public holidays and Sabbath days
- Any text already in the selected text box

It does not contain your events, notes, merit entries or photos. Google processes the request under its own terms (linked below). If you don't tap Suggest text, nothing is sent.

---

## 6. The web app

The web app works the same way as the phone app, with your data kept in your browser's storage. It also loads Telegram's Mini App script from telegram.org, so it can run inside Telegram; Telegram receives that request like any website visit. Inside Telegram, the app can show your Telegram username in Settings, on your device only. It sends nothing to Telegram.

---

## 7. Permissions

**Android:** internet and network state (Firebase, holiday updates); notifications, exact alarms, vibration, wake lock and "run at startup" (reminders that survive a restart); foreground and background work (refreshing widgets); and, from the Firebase libraries, the advertising ID and install referrer, used only as described in section 3.

**iOS:** notifications (reminders); camera and photo library (adding photos to Calendar Studio and saving exports), only when you use those features; background refresh (widgets); and an app group shared with the app's widgets and watch app.

The app does not use your location, contacts, microphone or calendar accounts.

---

## 8. Third parties

- **Google Firebase** (Analytics, Crashlytics, Remote Config, App Check, AI Logic with Gemini): [Google Privacy Policy](https://policies.google.com/privacy), [Firebase privacy and security](https://firebase.google.com/support/privacy), [Gemini API terms](https://ai.google.dev/gemini-api/terms)
- **Google Play Integrity** and **Apple App Attest** for App Check
- **Apple WatchConnectivity**, between your own iPhone and Apple Watch
- **Telegram**, only for the web app (section 6)

We do not use advertising networks, data brokers or cross-app tracking, and we do not sell or rent any data.

---

## 9. Children

The app is suitable for all ages. It does not ask for names, email addresses or other personal information, and analytics and crash reports stay off unless they are turned on.

---

## 10. Your choices and rights

- Turn Analytics and crash reports on or off in **Settings › Privacy & Data**.
- Edit or delete your events, notes and merit entries in the app, or uninstall it to remove all local data.
- Turn off notifications, or remove widgets and the watch apps, at any time.
- Ask us about, or ask us to delete, analytics or crash data related to your device by email. Because this data is not linked to your name, we may need your help to identify it. The steps are at [calendar.kyawzayartun.com/en/delete-data](https://calendar.kyawzayartun.com/en/delete-data).

Depending on where you live (for example under the GDPR or CCPA), you may have rights to access, correct, delete or object to the processing of your data. Contact us and we will respond within 30 days.

---

## 11. Changes to this policy

When we change this policy, we update the date at the top and the copy in the app (Settings › About › Privacy Policy) and on [calendar.kyawzayartun.com](https://calendar.kyawzayartun.com/en/privacy). If a change affects what is collected, we will say so in the app's What's new notes.

---

## 12. Contact

**Email:** kyawzayartun.contact@gmail.com

**Website:** https://calendar.kyawzayartun.com
''';
}
