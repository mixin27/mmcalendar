class AppConstants {
  // App Information
  static const String appName = 'Myanmar Calendar';
  static const String appVersion = '2.1.3';
  static const String appBuildNumber = '207';

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

**Last Updated: November 4, 2025**

## Introduction

Thank you for using Myanmar Calendar ("we," "our," or "the App"). We respect your privacy and are committed to protecting your personal information. This Privacy Policy explains how we collect, use, and safeguard your data when you use our mobile application.

---

## Information We Collect

### 1. Information We DO NOT Collect

Myanmar Calendar does not collect:

- Personal identification information (name, email, phone number)
- Location data or GPS coordinates
- Contact lists or social media information
- Payment information (app is free)
- Device identifiers (IMEI, MAC address, etc.) - *except as noted below for Firebase*
- **Your event details, descriptions, or locations**
- **Your reminder times or notification preferences**

### 2. Information Stored Locally on Your Device

The following data is stored **ONLY** on your device and never transmitted to our servers:

- **App Settings**: Your theme preferences, language selection, calendar configuration
- **User Events**: All events, reminders, and recurring events you create
  - Event titles, descriptions, and locations
  - Event dates, times, and durations
  - Event categories and priorities
  - Recurring event rules and exceptions
  - Notification settings for events
  - Event completion status
- **Custom Holidays**: Personal holidays you add
- **Event Categories**: Custom event categories you create
- **Notes**: Notes you create

All local data is stored using a secure SQLite database on your device with the following security measures:
- Database encryption at rest
- Secure data access through our app only
- No cloud synchronization (unless you explicitly enable backup in future)
- Complete data isolation - we have zero access to your event data

**Important**: Your event data never leaves your device. We cannot see, access, or share your event information.

### 3. Information Collected by Firebase

We use **Firebase Analytics** and **Firebase Crashlytics** to improve app performance and reliability. These services collect the following information:

#### Firebase Analytics Collects:

- App events and user interactions (e.g., which features you use)
  - *Example: "User created an event" (NOT the event details)*
  - *Example: "User set a reminder" (NOT when or what for)*
  - *Example: "User viewed calendar" (NOT what dates or events)*
- App session data (e.g., when you open the app, how long you use it)
- Device information (device type, OS version, language setting)
- Approximate location based on IP address (not exact GPS)
- Performance metrics and app crashes

#### Firebase Crashlytics Collects:

- Crash logs and error reports
- Stack traces from app crashes
- Device model and OS version
- App version information
- Custom error messages (sanitized - no personal data)

#### What Firebase Does NOT Collect:

- Your personal identity (name, email, phone number)
- Your calendar data or events
- Your event titles, descriptions, or locations
- Your reminder times or notification settings
- Your precise location
- Your browsing history outside the app
- Any content you create in the app

### 4. How We Use Firebase Data

We use this information to:

- Identify and fix bugs and crashes
- Improve app performance and stability
- Understand which features are most popular
- Monitor app health and reliability
- Enhance the user experience
- Optimize notification delivery
- Improve event creation workflow

---

## Local Notifications and Reminders

### How Event Notifications Work

Myanmar Calendar uses **local notifications** scheduled on your device:

- **Scheduled Locally**: All notifications are created and managed by your device operating system
- **No Server Required**: Notifications work completely offline without any internet connection
- **Privacy First**: Notification content (event title, time, location) never leaves your device
- **Your Control**: You can enable/disable notifications anytime in app settings

### What Notifications Collect

**We do NOT collect**:
- When notifications are triggered
- What notifications you receive
- How you interact with notifications
- Notification content or timing

**System Collects** (handled by Android/iOS, not by us):
- Basic notification delivery metrics (handled by your device OS)
- These metrics are not accessible to our app or Firebase

### Notification Permissions

When you enable event reminders, the app requests:
- **Android**: `POST_NOTIFICATIONS` permission for Android 13+
- **iOS**: Notification permission through system prompt

You can revoke these permissions anytime through device settings.

---

## Recurring Events and Exceptions

### How Recurring Events Work

Myanmar Calendar implements recurring events with a "master event + virtual instances" pattern:

- **Master Event**: One database entry containing the recurrence rule
- **Virtual Instances**: Generated on-demand when viewing the calendar (not stored)
- **Exceptions**: Modifications to specific occurrences (stored locally)
  - Completed instances
  - Deleted instances
  - Modified instances (changed time, title, etc.)

### Privacy of Recurring Event Data

All recurring event data is stored locally:
- Recurrence patterns (daily, weekly, monthly, yearly)
- Exception dates and modifications
- Instance-specific changes
- Completion status of individual occurrences

**We do NOT collect**:
- Your recurrence patterns
- How many recurring events you create
- Which occurrences you complete or modify

---

## Data Sharing and Third Parties

### Firebase Privacy

Firebase is operated by Google and processes data according to:

- Google's Privacy Policy: https://policies.google.com/privacy
- Firebase Terms of Service: https://firebase.google.com/terms

Firebase may share aggregated, non-personal information with Google for their services, but they do not share personal identifying information with advertisers.

### Third-Party Services We Use

- **Firebase Analytics** (Google) - For app analytics and crash reporting
- **Firebase Crashlytics** (Google) - For error tracking and reporting

We do NOT use:

- Third-party advertising networks
- Social media analytics
- User tracking services
- Data brokers or marketing platforms
- Cloud storage services (unless you opt-in to future backup feature)

### Data Sharing

We do NOT share your data with:

- Third-party advertisers
- Marketing companies
- Social media platforms
- Data brokers
- Any other organizations except as required by law

**Your event data is never shared** because it never leaves your device.

---

## Data Storage and Security

### Where Your Data is Stored

- **Local Data**: Stored encrypted on your device using SQLite
  - Event database file
  - Settings database file
  - Categories database file
- **Firebase Data**: Stored on Google's secure servers in multiple regions
  - Anonymous analytics
  - Crash reports
  - Performance metrics

### Security Measures

#### Local Data Security:
- SQLite database encryption
- Secure file storage in app sandbox
- No external access without device unlock
- Protected by your device's security (PIN/password/biometric)

#### Network Security:
- HTTPS encryption for all Firebase communication
- Certificate pinning
- Secure authentication tokens

#### Application Security:
- Regular security audits
- Dependency vulnerability scanning
- Secure coding practices
- Code obfuscation in production builds

---

## Your Rights and Choices

### Control Your Data

1. **View Your Events**: All your event data is accessible within the app
2. **Export Your Data**: Export events to ICS/CSV format (future feature)
3. **Delete Events**: Delete individual events or clear all events
4. **Delete Local Data**: Uninstall the app to remove all local data from your device
5. **Opt Out of Crashlytics**:
   - On Android: You can disable Firebase Crashlytics in app settings
   - On iOS: You can disable analytics in System Settings > Privacy > Analytics

### Firebase Opt-Out

To opt out of Firebase Analytics collection:

- **Android**: Open the app, go to Settings > Privacy, and toggle "Analytics" off
- **iOS**: Go to System Settings > Privacy > Analytics and disable "Share iPhone Analytics"

Note: You cannot fully opt out of Crashlytics while using the app, as it's necessary for stability reporting. Uninstalling the app removes all associated data.

### Event Data Control

You have complete control over your event data:

- **Create**: Add events with any information you choose
- **Read**: View all your events anytime
- **Update**: Modify events including recurring instances
- **Delete**: Remove events permanently
- **Export**: Export to standard calendar formats (future feature)
- **Clear All**: Wipe all event data from Settings

---

## Permissions

### Android Permissions

Myanmar Calendar requests **minimal permissions**:

#### Current Permissions:
- **INTERNET**: Required for Firebase Analytics and Crashlytics

#### Event & Notification Permissions:
- **POST_NOTIFICATIONS** (Android 13+): For event reminder notifications
  - Only requested when you enable reminders
  - Can be revoked in system settings
  - Notifications still work locally without this permission (silent reminders)
- **SCHEDULE_EXACT_ALARM** (Android 12+): For precise reminder timing
  - Ensures notifications trigger at exact scheduled times
  - Only requested when you create a notification
  - Required for reliable event reminders
- **USE_EXACT_ALARM** (Android 14+): Alternative permission for exact alarms
- **VIBRATE**: For haptic feedback and reminder vibrations
  - Provides tactile feedback when creating events
  - Vibrates device for notification alerts
- **RECEIVE_BOOT_COMPLETED**: To reschedule notifications after device restart
  - Ensures your reminders persist after rebooting
  - Only schedules notifications you already created

#### Future Permissions (Optional Cloud Backup):
- **ACCESS_NETWORK_STATE**: To check internet connectivity for backup

### iOS Permissions

- **Network**: Required for Firebase
- **Notifications**: Only if you enable event reminders
- **Background Refresh**: To reschedule notifications (system manages this)

### Permission Explanations

When requesting permissions, we explain:
- Why we need the permission
- What features require it
- What happens if you deny it
- How to revoke it later

All permissions are optional except INTERNET (required for crash reporting).

---

## Information We Collect and How We Use It

### App Usage Analytics

**What we collect**:
- Which features you use and how often
  - *Example: "Event creation feature used 50 times today"*
  - *NOT: "User created event titled 'Doctor Appointment'"*
- How long you use the app
- App crashes and errors
- Device type and OS version
- Performance metrics

**How we use it**:
- Improve app performance
- Fix bugs and crashes
- Understand user preferences
- Prioritize feature development
- Optimize event creation workflow
- Improve notification reliability

**Examples**:
- If we see many crashes when creating recurring events, we prioritize fixing it
- If event notifications fail frequently on certain devices, we investigate
- If users rarely use custom categories, we may redesign the feature
- If crashes spike on Android 14, we test compatibility

### Error and Crash Reporting

**What we collect**:
- When the app crashes, what caused it
- Error logs and stack traces (sanitized)
- Device information at time of crash
- App state before crash (no personal data)

**How we use it**:
- Identify critical bugs
- Fix errors quickly
- Improve app stability
- Test fixes on various devices
- Ensure notification scheduling works reliably

**Sanitization Example**:
```
❌ Bad: "Failed to create event 'Doctor Appointment at 2pm'"
✅ Good: "Failed to create event with notification at index 2"
```

---

## Children's Privacy

Myanmar Calendar is suitable for all ages, including children under 13. Since we only collect aggregate analytics data (not personal information), the app complies with:

- COPPA (Children's Online Privacy Protection Act)
- GDPR requirements for children's privacy
- Similar international regulations

We do not:
- Collect personal information from children
- Allow children to share personal information
- Target advertising to children (we have no ads)
- Collect event data from children's calendars

Parents/Guardians can:
- Monitor app usage through device parental controls
- Disable analytics in app settings
- Delete all event data at any time
- Review this privacy policy with children

---

## Data Retention

### Local Data on Your Device
- **Events**: Stored indefinitely until you delete them
  - Individual event deletion
  - Bulk deletion options
  - Clear all events from settings
- **Settings**: Stored until you change them or uninstall
- **Categories**: Stored until you delete them
- **All Data**: Removed when you uninstall the app
- You have full control over your local data

### Firebase Analytics Data
- Retained for 14 months by default
- Automatically deleted after 14 months of inactivity
- You can request data deletion at any time

### Firebase Crashlytics Data
- Retained for 90 days
- Older data is automatically deleted
- Critical crash data may be retained longer for analysis

### Notification Data
- **Local Notifications**: Stored on device until triggered or cancelled
- **Scheduled Notifications**: Managed by your device's notification system
- **Past Notifications**: Automatically cleared by your OS
- We do NOT have access to notification history

### Cloud Backup Data (Future Feature)
- Only if you opt-in
- End-to-end encrypted
- You can delete anytime from settings
- Deleted within 30 days of request
- Includes events, categories, and settings
- Excludes analytics and crash data

---

## Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Changes will be reflected by updating the "Last Updated" date at the top.

### How We Notify You

- In-app notification for major changes
- Updated policy in app settings
- Play Store/App Store description update
- Email notification (if we add account features in future)

### Your Continued Use

Continued use of the app after policy changes constitutes acceptance of those changes. For major changes affecting your data rights, we'll request explicit consent.

---

## International Users

Myanmar Calendar complies with international privacy regulations:

- **GDPR** (European Union)
- **CCPA** (California, USA)
- **UK GDPR** (United Kingdom)
- **PIPEDA** (Canada)
- **Privacy Act** (Australia)
- **LGPD** (Brazil)

If you are located in the EU, you have additional rights:
- Right to access your data
- Right to deletion
- Right to correct inaccurate data
- Right to data portability
- Right to object to processing
- Right to restrict processing
- Right not to be subject to automated decision-making

---

## Open Source Components

Myanmar Calendar uses open-source packages with their own privacy policies:

- **Flutter Framework**: https://flutter.dev/privacy
- **Dart Language**: https://dart.dev/privacy
- **Firebase SDK**: https://firebase.google.com/terms
- **Drift (SQLite)**: Local database - no data collection
- **flutter_local_notifications**: Local notifications - no data collection

No open-source components collect personal data without your knowledge.

---

## Contact Us

If you have questions or concerns about this Privacy Policy or our privacy practices:

**Email**: kyawzayartun.contact@gmail.com

**Website**: https://kyawzayartun.com/apps/myanmar-calendar/privacy

**Response Time**: We aim to respond to all inquiries within 48 hours.

**Data Requests**: For GDPR/CCPA data requests, use subject line "Data Rights Request"

---

## Your Privacy Rights (GDPR and Similar Laws)

If you are in a jurisdiction with privacy laws (EU, California, etc.), you have the right to:

### Right to Access
- Request a copy of the analytics data we collect about you
- **Note**: Your event data is already on your device - you have full access
- Submit a request via email with "Data Access Request" as subject

### Right to Deletion
- Request deletion of your Firebase analytics data
- Delete your local event data anytime in app settings
- **Local Data**: Delete through app settings or uninstall
- **Firebase Data**: Request deletion via email
- Submit a request via email with "Data Deletion Request" as subject

### Right to Portability
- Export your event data to standard formats (future feature)
- Request your Firebase data in a portable format
- We will provide exported data within 30 days

### Right to Object
- Object to Firebase analytics collection
- Disable analytics in app settings
- Opt out of crash reporting (with reduced support)
- Uninstall the app

### Right to Rectification
- Correct inaccurate information in your local app data
- Update or fix event details anytime
- Firebase analytics data cannot be individually rectified but is automatically deleted after 14 months

---

## Cookies and Tracking

Myanmar Calendar does NOT use:
- Cookies
- Tracking pixels
- Web beacons
- Device fingerprinting
- Cross-app tracking
- Location tracking
- Behavioral profiling

Firebase may use minimal cookies for authentication purposes only (if we add cloud features).

---

## Advertising

Myanmar Calendar is **100% ad-free** and will always remain ad-free.

We will never:
- Show advertisements
- Sell ad space
- Share data with advertisers for ad targeting
- Use data for behavioral advertising
- Sell your event data to third parties
- Monetize your personal information

Our business model: One-time purchase or freemium features (never ads or data selling).

---

## Updates and Notifications

### App Updates
- Downloaded through official app stores
- No additional data collection during updates
- Update notes explain any privacy changes

### Push Notifications
- **Only local notifications** for features you enable
- No remote push notifications (no server-side notifications)
- No marketing or promotional notifications
- Fully controlled by you
- Event reminders only
- Can be disabled per-event or globally

### Notification Content
- Contains only information you entered (event title, time)
- Stored and displayed locally on your device
- Never sent to our servers
- Not visible to us or any third party

---

## Transparency and Your Trust

We believe in transparent data practices:

**What we collect**:
- App analytics and crash reports (via Firebase)
- No personal information
- No event details

**How we use it**:
- Improve app quality and fix bugs
- Optimize event creation and notification features
- Enhance user experience

**Who has access**:
- Only our development team and Google Firebase
- Zero access to your event data

**Your control**:
- You can opt out of analytics anytime
- Complete control over your event data
- Delete all data by uninstalling

We cannot misuse data we don't collect. Your events are private by design - they never leave your device.

---

## Data Breach Notification

In the unlikely event of a data breach:

### What We'll Do
1. Investigate the breach immediately
2. Notify affected users within 72 hours (GDPR requirement)
3. Report to relevant authorities if required
4. Provide clear information about what data was affected
5. Offer remediation steps and support

### What's at Risk
Since your event data never leaves your device, a server-side breach cannot expose:
- Your events
- Your reminders
- Your categories
- Your personal calendar information

Only anonymous analytics data is on our servers, which contains no personal information.

---

## Summary

Myanmar Calendar:
- Works completely offline for calendar and event functions
- **Stores all event data locally - never on our servers**
- **Your events are 100% private and never transmitted**
- Uses local notifications - no server required
- Collects minimal analytics data to improve quality
- Uses industry-standard Firebase for crash reporting
- Respects your privacy with local-first data storage
- Has zero ads and zero tracking
- Allows you to opt out of analytics
- Respects international privacy laws
- Gives you complete control over your event data

### Privacy by Design
- **Local-First**: All calendar data stays on your device
- **Zero-Knowledge**: We cannot see your events, even if we wanted to
- **Offline-Capable**: Full functionality without internet
- **Transparent**: Clear about what little data we collect
- **User Control**: You own and control all your data

---

**Last Updated**: November 4, 2025
**Version**: 2.1
**Effective Date**: November 4, 2025

**Changelog**:
- Added section on Event and Notification features
- Clarified local-first data storage for events
- Explained notification privacy and permissions
- Added details about recurring events and exceptions
- Updated permissions list for event reminders
- Clarified what analytics do NOT include (event details)

---

© 2024-2025 Kyaw Zayar Tun. All rights reserved.
''';
}
