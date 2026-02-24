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

  /core
  /data
  /app_remote_config
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

## What Was Changed In This Refactor Pass

- Removed active `AppEventBus` usage from BLoCs and use cases.
- Removed event bus exports/dependency from `core`.
- Added explicit BLoC coordination in calendar UI for month-based event sync.
- Added new package layers:
  - `packages/shared/core`
  - `packages/shared/ui_kit`
  - `packages/shared/localizations`
  - `packages/integrations/database`
  - `packages/integrations/firebase`
- Migrated app bootstrap/DI to integration packages for:
  - Firebase consent-aware initialization
  - Database lifecycle access

## Next Migration Steps

1. Move remote config + holiday parsing contracts behind integration interfaces.
2. Move drift implementation details from `data` into `integrations/database`.
3. Move analytics/crashlytics call sites from feature packages to domain-safe interfaces.
4. Adopt `shared_*` packages from feature/app imports and retire direct `core/localizations` usage.
5. Add CI dependency-boundary checks per package layer.
