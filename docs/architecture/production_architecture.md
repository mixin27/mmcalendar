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

  /core (compatibility shim)
  /localizations (compatibility shim)
  /data (compatibility shim)
  /app_remote_config (compatibility shim)
  /features/firebase_analytics_app (compatibility shim)
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
- Use `./scripts/analyze_all.sh` for boundary check + static analysis.
- Use `./scripts/test_all.sh` for boundary check + test run.
- CI enforcement: `.github/workflows/quality_gate.yml` runs these checks on pull requests and `main`.

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
- Moved drift implementation into `packages/integrations/database`.
- Moved Firebase analytics/crashlytics/remote-config implementation into `packages/integrations/firebase`.
- Converted legacy `data`, `firebase_analytics_app`, and `app_remote_config` to compatibility shims.

## Next Migration Steps

1. Move remote config + holiday parsing behind explicit integration interfaces.
2. Introduce domain-safe analytics/crashlytics ports and keep SDK types out of feature code.
3. Convert remaining direct `core/localizations` usage into `shared_*` only and retire legacy packages.
4. Extend boundary checks with stricter feature-to-feature dependency allowlists.
5. Plan shim package deprecation/removal once downstream imports are fully migrated.
