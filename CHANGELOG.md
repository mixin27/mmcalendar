# Changelog

All notable changes to Myanmar Calendar App will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Planned Features
- Events and reminders system
- Recurring events support
- Local notifications
- Notes feature
- Cloud backup and sync
- Search functionality

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

---

## Version Numbering

We use [Semantic Versioning](https://semver.org/):
- **MAJOR**: Incompatible API changes
- **MINOR**: New functionality (backwards compatible)
- **PATCH**: Bug fixes (backwards compatible)

Format: `MAJOR.MINOR.PATCH`

Example: `1.2.3`
- 1 = Major version
- 2 = Minor version
- 3 = Patch version

---

## Release Notes Template

For future releases, we'll follow this format:

### [X.Y.Z] - YYYY-MM-DD

#### Added
- New features

#### Changed
- Changes to existing functionality

#### Deprecated
- Features marked for removal

#### Removed
- Removed features

#### Fixed
- Bug fixes

#### Security
- Security improvements

---

## Upcoming Releases

### [2.1.0] - Expected Q2 2026

**Focus: Events & Reminders**

#### Planned Features
- ✨ Events creation and management
- ✨ Event categories with custom colors
- ✨ Recurring events (daily, weekly, monthly, yearly)
- ✨ Custom recurrence patterns
- ✨ Event reminders
- ✨ Multiple reminder times
- ✨ Local notifications
- ✨ Notes system
- ✨ Tags for organization
- ✨ Event search and filter

#### Improvements
- Enhanced day details page with events
- Calendar integration with event indicators
- Quick event creation
- Event templates

---

### [2.2.0] - Expected Q3 2026

**Focus: Cloud Backup & Sync**

#### Planned Features
- ☁️ Optional cloud backup
- ☁️ Multi-device sync
- ☁️ Encrypted backups
- ☁️ Automatic backup scheduling
- ☁️ Restore from backup
- ☁️ Backup history
- ☁️ Data export/import (ICS, CSV, JSON)

#### Improvements
- Enhanced settings page
- Backup management UI
- Conflict resolution
- Data integrity checks

---

### [3.0.0] - Expected Q4 2026

**Focus: Advanced Features**

#### Planned Features
- 📱 Home screen widgets
- 🔍 Advanced search
- 📊 Analytics and insights
- 🌤️ Weather integration
- 📷 Attach images to events
- 👥 Share events
- 🗓️ Calendar subscriptions
- 🌐 Web version

#### Improvements
- Performance optimizations
- Enhanced UI/UX
- Accessibility improvements
- More language support

---

## Migration Guides

### From 1.0.x to 1.1.x (When Available)

No breaking changes expected. New features will be additive.

### Database Migrations

Handled automatically by the app. Your data will be preserved.

---

## Support

- 🐛 **Report bugs**: [GitHub Issues](https://github.com/mixin27/mmcalendar/issues)
- 💡 **Feature requests**: [GitHub Discussions](https://github.com/mixin27/mmcalendar/discussions)
- 📧 **Email**: [kyawzayartun.contact@gmail.com](kyawzayartun.contact@gmail.com)
- ⭐ **Rate us**: [Play Store](https://play.google.com/store/apps/details?id=dev.mixin27.mmcalendar)
<!-- | [App Store](https://apps.apple.com/app/your-app-id) -->

---

## Contributors

See [CONTRIBUTORS.md](CONTRIBUTORS.md) for a list of all contributors.

---

**Note**: This changelog is updated with each release. For the latest development updates, check our [GitHub repository](https://github.com/mixin27/mmcalendar).

---

© 2024 Kyaw Zayar Tun. All rights reserved.
