# shared_core

Shared core facade package used during the architecture migration.

## Port Contracts

- `AnalyticsPort`: SDK-agnostic analytics contract for feature/application layers.
- `CrashlyticsPort`: SDK-agnostic crash reporting contract for feature/application layers.
- `DisplayPreferencesPort`: Shared display preference contract for feature/application layers.
- `CalendarDisplayConfigPort`: Shared calendar display/config contract for feature/application layers.
- `EventMarkersPort`: Shared calendar-event marker/day-event contract for feature/application layers.
- `HolidayConfigPort`: SDK-agnostic holiday config retrieval/decoding contract.
- `HolidayOverridesPort`: Shared custom holiday override contract for feature/application layers.
- `MonthPreviewPort`: Shared month-preview UI contract for feature/application layers.
- `RemoteConfigPort`: SDK-agnostic remote config contract for feature/application layers.
