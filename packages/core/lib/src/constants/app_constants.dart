class AppConstants {
  // App Information
  static const String appName = 'Myanmar Calendar';
  static const String appVersion = '2.1.2';
  static const String appBuildNumber = '206';

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

**Last Updated: October 17, 2025**

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

### 2. Information Stored Locally on Your Device

The following data is stored **ONLY** on your device and never transmitted to our servers:

- App Settings: Your theme preferences, language selection, calendar configuration
- User Events: Events and reminders you create (Phase 2)
- Custom Holidays: Personal holidays you add (Phase 2)
- Notes: Notes you create (Phase 2)

All local data is stored using a secure SQLite database on your device. We have no access to this data.

### 3. Information Collected by Firebase

We use **Firebase Analytics** and **Firebase Crashlytics** to improve app performance and reliability. These services collect the following information:

#### Firebase Analytics Collects:

- App events and user interactions (e.g., which features you use)
- App session data (e.g., when you open the app, how long you use it)
- Device information (device type, OS version, language setting)
- Approximate location based on IP address (not exact GPS)
- Performance metrics and app crashes

#### Firebase Crashlytics Collects:

- Crash logs and error reports
- Stack traces from app crashes
- Device model and OS version
- App version information
- Custom error messages

#### What Firebase Does NOT Collect:

- Your personal identity (name, email, phone number)
- Your calendar data or events
- Your precise location
- Your browsing history outside the app

### 4. How We Use Firebase Data

We use this information to:

- Identify and fix bugs and crashes
- Improve app performance and stability
- Understand which features are most popular
- Monitor app health and reliability
- Enhance the user experience

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

### Data Sharing

We do NOT share your data with:

- Third-party advertisers
- Marketing companies
- Social media platforms
- Data brokers
- Any other organizations except as required by law

---

## Data Storage and Security

### Where Your Data is Stored

- **Local Data**: Stored encrypted on your device using SQLite
- **Firebase Data**: Stored on Google's secure servers in multiple regions

### Security Measures

- Encryption of data in transit and at rest
- Secure authentication and authorization
- Regular security audits
- HTTPS encryption for all network communication
- Compliance with industry security standards

---

## Your Rights and Choices

### Control Your Data

1. **View Analytics**: You cannot access raw Firebase analytics data, but we use it only to improve the app
2. **Delete Local Data**: Uninstall the app to remove all local data from your device
3. **Opt Out of Crashlytics**:
   - On Android: You can disable Firebase Crashlytics in app settings (future feature)
   - On iOS: You can disable analytics in System Settings > Privacy > Analytics

### Firebase Opt-Out

To opt out of Firebase Analytics collection:

- **Android**: Open the app, go to Settings > Privacy, and toggle "Analytics" off
- **iOS**: Go to System Settings > Privacy > Analytics and disable "Share iPhone Analytics"

Note: You cannot fully opt out of Crashlytics while using the app, as it's necessary for stability reporting. Uninstalling the app removes all associated data.

---

## Permissions

### Android Permissions

Myanmar Calendar requests **minimal permissions**:

#### Current Permissions:
- **INTERNET**: Required for Firebase Analytics and Crashlytics

#### Future Permissions:

**Phase 2 (Events & Notifications):**
- `VIBRATE`: For haptic feedback and reminder vibrations
- `POST_NOTIFICATIONS`: For event reminders
- `SCHEDULE_EXACT_ALARM`: For precise reminder timing

**Phase 3 (Cloud Backup - Optional):**
- `ACCESS_NETWORK_STATE`: To check internet connectivity

### iOS Permissions

- **Network**: Required for Firebase
- **Notifications**: Only if you enable event reminders (Phase 2)

All permissions are requested only when needed with clear explanation.

---

## Information We Collect and How We Use It

### App Usage Analytics

**What we collect**:
- Which features you use and how often
- How long you use the app
- App crashes and errors
- Device type and OS version

**How we use it**:
- Improve app performance
- Fix bugs and crashes
- Understand user preferences
- Prioritize feature development

**Examples**:
- If we see many crashes in a specific feature, we prioritize fixing it
- If a feature is rarely used, we may redesign it for better usability
- If crashes spike on certain device types, we investigate compatibility issues

### Error and Crash Reporting

**What we collect**:
- When the app crashes, what caused it
- Error logs and stack traces
- Device information at time of crash

**How we use it**:
- Identify critical bugs
- Fix errors quickly
- Improve app stability
- Test fixes on various devices

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

---

## Data Retention

### Local Data on Your Device
- Stored indefinitely until you delete it
- Removed when you uninstall the app
- You have full control over your local data

### Firebase Analytics Data
- Retained for 14 months by default
- Automatically deleted after 14 months of inactivity
- You can request data deletion at any time

### Firebase Crashlytics Data
- Retained for 90 days
- Older data is automatically deleted
- Critical crash data may be retained longer for analysis

### Cloud Backup Data (Future Feature)
- Only if you opt-in
- You can delete anytime from settings
- Deleted within 30 days of request

---

## Changes to This Privacy Policy

We may update this Privacy Policy from time to time. Changes will be reflected by updating the "Last Updated" date at the top.

### How We Notify You

- In-app notification for major changes
- Updated policy in app settings
- Play Store/App Store description update

### Your Continued Use

Continued use of the app after policy changes constitutes acceptance of those changes.

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

---

## Open Source Components

Myanmar Calendar uses open-source packages with their own privacy policies:

- **Flutter Framework**: https://flutter.dev/privacy
- **Dart Language**: https://dart.dev/privacy
- **Firebase SDK**: https://firebase.google.com/terms

No open-source components collect personal data without your knowledge.

---

## Contact Us

If you have questions or concerns about this Privacy Policy or our privacy practices:

**Email**: kyawzayartun.contact@gmail.com

**Website**: https://kyawzayartun.com/apps/myanmar-calendar/privacy

**Response Time**: We aim to respond to all inquiries within 48 hours.

---

## Your Privacy Rights (GDPR and Similar Laws)

If you are in a jurisdiction with privacy laws (EU, California, etc.), you have the right to:

### Right to Access
- Request a copy of the data we collect about you
- Submit a request via email with "Data Access Request" as subject

### Right to Deletion
- Request deletion of your Firebase analytics data
- Your local data is always under your control
- Submit a request via email with "Data Deletion Request" as subject

### Right to Portability
- Request your data in a portable format
- We will provide exported data within 30 days

### Right to Object
- Object to Firebase analytics collection
- Disable analytics in app settings
- Uninstall the app

### Right to Rectification
- Correct inaccurate information in your local app data
- Firebase analytics data cannot be individually rectified but is automatically deleted after 14 months

---

## Cookies and Tracking

Myanmar Calendar does NOT use:
- Cookies
- Tracking pixels
- Web beacons
- Device fingerprinting
- Cross-app tracking

Firebase may use cookies for authentication purposes only.

---

## Advertising

Myanmar Calendar is **100% ad-free** and will always remain ad-free.

We will never:
- Show advertisements
- Sell ad space
- Share data with advertisers for ad targeting
- Use data for behavioral advertising

---

## Updates and Notifications

### App Updates
- Downloaded through official app stores
- No additional data collection during updates

### Push Notifications
- Only local notifications for features you enable
- No marketing or promotional notifications
- Fully controlled by you

---

## Transparency and Your Trust

We believe in transparent data practices:

**What we collect**: App analytics and crash reports (via Firebase)
**How we use it**: Improve app quality and fix bugs
**Who has access**: Only our development team and Google Firebase
**Your control**: You can opt out of analytics anytime

We cannot misuse data we don't need. We collect only what's necessary to provide a stable, high-quality app.

---

## Summary

Myanmar Calendar:
- Works completely offline for calendar functions
- Collects minimal analytics data to improve quality
- Uses industry-standard Firebase for crash reporting
- Respects your privacy with local-first data storage
- Has zero ads and zero tracking
- Allows you to opt out of analytics
- Respects international privacy laws

---

**Last Updated**: October 17, 2025
**Version**: 2.0
**Effective Date**: October 17, 2025

---

© 2024 Kyaw Zayar Tun. All rights reserved.
''';
}
