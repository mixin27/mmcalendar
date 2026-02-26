# Production Architecture Blueprint

## Goals

- Keep UI behavior stable while improving maintainability.
- Keep BLoC for state management.
- Remove global event-driven coupling (`AppEventBus`).
- Isolate shared concerns and integrations into dedicated packages.

## Target Package Layers

```text
/apps
  /myanmar_calendar

/packages
  /shared
    /core
    /ui_kit
    /localizations

  /integrations
    /firebase
    /database
    /telegram_web

  /features
    /calendar
    /views
    /converter
    /settings
    /events
    /holidays
    /notes
    /home_widgets

```

## Dependency Rules

- `features/*` depend on domain contracts and shared packages.
- `features/*` do not publish or consume app-wide global events.
- `integrations/*` own external SDK wiring.
- `apps/*` act as the composition root only.

## Runtime Flow

```text
UI -> Bloc Event -> UseCase -> Repository Contract -> Integration Adapter -> State
```

## Automated Guardrails

- Run `dart run tool/check_dependency_boundaries.dart` to enforce package-layer boundaries.
- Boundary script now enforces explicit feature-to-feature dependency allowlists.
- Use `./scripts/analyze_all.sh` for boundary check + static analysis.
- Use `./scripts/test_all.sh` for boundary check + test run.
- CI enforcement: `.github/workflows/quality_gate.yml` runs these checks on pull requests and `main`.

## Integration Ports

- `AnalyticsPort`, `CrashlyticsPort`, `RemoteConfigPort`, `HolidayConfigPort`, `HolidayOverridesPort`, `DisplayPreferencesPort`, `CalendarDisplayConfigPort`, `EventActionsPort`, `EventMarkersPort`, and `MonthPreviewPort` are defined in `packages/shared/core`.
- Feature packages consume these ports instead of Firebase SDK-facing services.
- `packages/integrations/firebase` provides the concrete implementations and DI wiring.
- `packages/features/holidays` provides holiday-override implementation wiring consumed through `HolidayOverridesPort`.
- `packages/features/settings` provides database-backed display preference wiring consumed through `DisplayPreferencesPort` and `CalendarDisplayConfigPort`.
- `packages/features/events` provides repository-backed marker/event wiring consumed through `EventMarkersPort` and navigation actions through `EventActionsPort`.
- `packages/features/calendar` provides month-preview UI wiring consumed through `MonthPreviewPort`.

## What Was Changed In This Refactor Pass

- Removed active `AppEventBus` usage from BLoCs and use cases.
- Removed event bus exports/dependency from `core`.
- Added shared-port based calendar event marker/day-event sync.
- Added new package layers:
  - `packages/shared/core`
  - `packages/shared/ui_kit`
  - `packages/shared/localizations`
  - `packages/integrations/database`
  - `packages/integrations/firebase`
- Migrated app bootstrap/DI to integration packages for:
  - Firebase consent-aware initialization
  - Database lifecycle access
- Moved drift implementation into `packages/integrations/database`.
- Moved Firebase analytics/crashlytics/remote-config implementation into `packages/integrations/firebase`.
- Moved holiday-config retrieval/JSON decoding behind `HolidayConfigPort` and Firebase integration adapter.
- Moved `calendar` and `settings` holiday override access behind `HolidayOverridesPort` (removed direct `holidays` feature dependency).
- Moved `calendar` display and calendar-config reads behind `CalendarDisplayConfigPort` (removed direct `settings` feature dependency).
- Moved `calendar` event markers/day-event reads behind `EventMarkersPort` (removed direct `events` feature dependency).
- Moved `calendar` event navigation flows behind `EventActionsPort` (removed direct event-route coupling).
- Moved `views` display preference reads behind `DisplayPreferencesPort` (removed direct `settings` feature dependency).
- Moved `views` month-preview rendering behind `MonthPreviewPort` (removed direct `calendar` feature dependency).
- Added strict feature-to-feature dependency allowlists in boundary checks.
- Retired legacy `core` and `localizations` shim packages.
- Retired legacy `data` and `app_remote_config` shim packages.

## Next Migration Steps

1. Continue reducing direct feature-to-feature dependencies until each feature depends only on shared contracts.
