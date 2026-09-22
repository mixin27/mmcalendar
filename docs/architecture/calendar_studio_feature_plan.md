# Calendar Studio — Product and Implementation Plan

## Status

Proposed. This document defines a new `calendar_studio` feature package. It does
not refactor `calendar_generation`; the current generator remains available as
a temporary legacy feature until Calendar Studio has reached release quality.

## Decision summary

Calendar Studio is a creation workspace, not an app preference. It must not be
reachable only from Settings.

## Mockup-aligned delivery contract

The clickable mockup is the Release 1 interaction specification, not merely a
style reference. The implementation must preserve its primary path:

```text
Home entry → Studio dashboard → Template gallery → Setup sheet → Editor
           → Preview + preflight → Export options → Progress → Done
```

The standalone `calendar_studio` package is delivered before app integration.
It owns this flow, document model, built-in templates, responsive editor UI,
scene preview, preflight rules, and public integration contracts. It does not
depend on this app's router, DI container, Drift database, Events feature, or
legacy generator. Instead, the app supplies project storage, canonical calendar
data, managed asset storage, Classic-import mapping, and export delivery by
implementing package ports.

Mockup requirements now explicit in Release 1:

- dashboard has empty, resume, project actions, and safe delete states;
- six templates: blank, wall, desk, annual, square, and story;
- setup is a mobile sheet with period, language, day-data visibility, week
  start, timezone, and output defaults;
- editor exposes selection, inspector, layers, add menu, page settings,
  page navigation, autosave state, undo/redo, and tap alternatives to gestures;
- phone uses canvas plus sheets/tools; wide layouts use layers, canvas, and
  inspector panes;
- preview shows safe/bleed guides and per-page navigation; warnings advise and
  errors block export; export reports incremental page progress;
- migration remains non-destructive: Classic data is only left untouched until
  each individual Studio project has saved successfully.

### Entry point and route

- Create a top-level route: `/studio`.
- Present a prominent **Create calendar** action on the Home calendar screen:
  - mobile: AppBar action and a first-class quick-action card above/below the
    month calendar;
  - tablet/desktop: a labelled `Calendar Studio` action in the NavigationRail
    leading area, plus the Home quick action.
- Open Studio as a full-screen workspace with its own AppBar and back button;
  do not add it as a sixth `NavigationBar` destination. The app already has
  five destinations, and a sixth would make the mobile navigation crowded.
- The legacy route remains `/settings/calendar-generation` during migration.
  It is labelled **Classic generator** and is removed only in the retirement
  milestone below.

This makes the feature discoverable for ordinary users while keeping browsing,
conversion, events, and settings navigation focused.

## Product goal

Let users produce attractive, accurate Myanmar calendars for print and digital
sharing without needing design software. A user selects a format, supplies any
personal content, edits a structured design, previews every page, and exports
the result with confidence that Myanmar dates, holidays, and other calendar
data are correct.

## Scope

### Release 1

- Project dashboard: create, duplicate, rename, delete, and resume projects.
- Built-in templates: monthly wall calendar, annual calendar, A4 portrait,
  A4 landscape, square social post, and story post.
- Structured blocks: calendar grid, title/text, image, logo, event list,
  holiday legend, and decorative shape.
- Direct manipulation: select, move, resize, layer, duplicate, hide, lock,
  delete, undo, and redo.
- Myanmar/Gregorian date display, holiday and astrology display controls,
  supported languages, timezone policy, and configurable week start.
- Local custom events selected from the existing Events feature.
- Autosave and a project version compatible with future migrations.
- PNG/JPEG, PDF, print, share, and multi-page image ZIP exports.

### Later releases

- Brand kits and reusable custom templates.
- ICS/CSV event import and export.
- SVG export for compatible projects.
- Advanced print controls: bleed, crop marks, printer margins, and CMYK
  guidance.
- Cloud backup/sharing only after a deliberate account and privacy design.

### Explicit non-goals for Release 1

- A fully unrestricted Canva-style editor.
- Collaborative editing or a public template marketplace.
- Changing the canonical Myanmar calendar calculation or holiday source from
  inside the design editor.

## Package and architectural boundary

Create a sibling feature package:

```text
packages/features/calendar_studio/
  lib/
    calendar_studio.dart
    src/
      data/
        datasources/
        repositories/
      di/
      domain/
        entities/
        repositories/
        usecases/
      presentation/
        bloc/
        pages/
        widgets/
      rendering/
        scene/
        preview/
        export/
        preflight/
```

Keep three concerns separate:

```text
Calendar settings + canonical date/holiday data + project document
                              ↓
                        Render scene
                   ↙          ↓          ↘
          Flutter preview   PDF export   raster export
```

The render scene is the only input to preview and export renderers. This is
required to prevent a preview that looks different from the downloaded or
printed file.

## Core domain model

`CalendarProject` is the persisted document. It is versioned and independent
of presentation state such as the currently selected editor tool.

```text
CalendarProject
├── id, name, schemaVersion, createdAt, updatedAt
├── calendarSource
│   ├── range (month or year)
│   ├── language, timezone policy, first day of week
│   └── date/holiday/astrology visibility
├── pages[]
│   ├── canvas (preset, width, height, safe area, bleed)
│   └── blocks[]
│       ├── calendar grid
│       ├── text
│       ├── image / logo
│       ├── event list / holiday legend
│       └── decoration
├── theme / optional brand-kit reference
└── default export preset
```

Every block has a stable ID, normalized bounds, rotation, z-index, visibility,
lock state, style, and a typed content payload. Blocks are structured: a
calendar-grid block exposes calendar-specific controls rather than arbitrary
editable text. This preserves correctness and enables reliable export.

## Data and persistence

### Calendar data service

Implement a pure `CalendarStudioDataService` that produces immutable calendar
page data from the selected date range and the existing calendar runtime.

It must:

- apply the configured first weekday to both weekday headers and grid offsets;
- expose Gregorian, Myanmar, moon, holiday, astrology, and custom-event data
  as separate fields;
- preserve current app language and timezone semantics;
- cache deterministic results by configuration and date range;
- never let editor content overwrite canonical date or holiday data.

### Storage

Persist projects, project pages/blocks, template metadata, and asset metadata
in Drift/SQLite. Use JSON payload columns for block-specific styles/content at
first, with a `schemaVersion` and explicit migration path. Store editor-only
preferences (snap-to-grid, last selected tool, recent export preset) in
SharedPreferences.

User-provided images must be copied into app-managed storage. Store a managed
asset ID and metadata rather than relying on transient picker URIs.

## User flow

1. User taps **Create calendar** from Home and lands on the Studio dashboard.
2. User chooses a built-in template or resumes an existing project.
3. The setup sheet selects month/year, language, calendar display options, and
   output preset. Sensible defaults come from app settings.
4. The editor opens with a live canvas and selected calendar page.
5. User edits blocks directly and uses the inspector for detailed settings.
6. User opens Preview to browse all generated pages and resolve preflight
   warnings.
7. User selects an export preset, then saves, shares, prints, or exports a ZIP.

### Responsive editor layout

- **Phone:** canvas first; bottom sheet for inspector; collapsible layers
  drawer; large primary Export button.
- **Tablet/desktop:** three panes—layers/template controls, canvas, and
  inspector—with a thumbnail strip for multi-page projects.
- Support touch targets, keyboard shortcuts on desktop, semantic labels, and
  a non-gesture path for all block actions.

## Rendering and exports

Create `RenderSceneBuilder` to resolve a project, calendar data, images, font
metrics, and layout into positioned rendering primitives.

- Flutter renders the scene for interactive preview.
- The PDF renderer writes vector text/shapes whenever possible and embeds
  Myanmar-capable fonts. Rasterize only image/effect content that needs it.
- PNG/JPEG renderer produces output from explicit dimensions and DPI.
- ZIP export streams multi-page image files rather than keeping all pages in
  memory.
- Preflight produces actionable errors/warnings for missing images, low source
  resolution, text overflow, low contrast, unsafe bounds, unsupported export
  blocks, and invalid print configuration.

Export presets include screen sharing, high-quality image, A4/A3 print, square
social, and story. The project preview must display the same safe/bleed areas
and canvas ratio used during export.

## Implementation phases

### Phase 0 — feature contract and visual design

- Confirm template list, supported paper/social presets, and fonts with
  Myanmar glyph coverage.
- Add the `/studio` route and visible Home/desktop entry points behind a
  feature flag.
- Produce wireframes and golden-reference designs for phone and desktop.

**Exit:** approved user flow and rendering contracts; no legacy code changed.

### Phase 1 — foundation

- Scaffold `calendar_studio`, DI registration, and route integration.
- Add Drift migrations/tables and project repository.
- Implement project serialization/versioning, asset repository, and calendar
  data service.
- Add unit tests for date range, week-start, locale, and migration behavior.

**Exit:** a blank or template project can be created, saved, reopened, and
generate correct immutable calendar data.

### Phase 2 — editor MVP

- Implement project dashboard and template picker.
- Implement canvas, selection, layers, inspector, autosave, undo/redo.
- Ship calendar-grid, text, image, and logo blocks.
- Support monthly and annual projects, including page thumbnails.

**Exit:** users can complete a branded monthly calendar and reopen the same
project without losing changes.

### Phase 3 — export and preflight

- Implement the shared render scene and preview renderer.
- Implement PNG/JPEG, vector-first PDF, print/share, and image ZIP export.
- Add preflight UI and export progress/cancellation.
- Add golden and integration tests that compare representative preview and
  exported output.

**Exit:** supported templates export correctly at target sizes with Myanmar
font coverage and no unresolved preflight errors.

### Phase 4 — content and polish

- Add event-list, holiday legend, and decoration blocks.
- Add custom events from the existing Events feature.
- Add template duplication, brand kits, accessibility work, and performance
  profiling for 12-page projects.

**Exit:** Calendar Studio is production-ready and the recommended creation
experience for all users.

### Phase 5 — migration and legacy retirement

- Offer one-time import of legacy generation settings/templates into Studio
  projects where the mapping is safe.
- Leave legacy data untouched until Studio import succeeds.
- Redirect the Settings entry to Studio, retain the Classic generator only for
  a defined deprecation release, then remove its route, DI registration,
  package dependency, storage keys, and legacy tests.

**Exit:** no in-app route references `calendar_generation`; removal is covered
by migration and regression tests.

## Testing requirements

- Unit: calendar data, project validation, serialization, migrations, export
  preset resolution, and preflight rules.
- Golden: each shipped template in English and Myanmar, portrait/landscape,
  monthly/annual, and selected calendar edge dates.
- Widget: project dashboard, inspector controls, selection/layers, undo/redo,
  and responsive editor layouts.
- Integration: create → edit → persist → reopen → export; multi-page ZIP;
  PDF page count and non-empty text/image checks.
- Manual: physical A4/A3 print verification, font glyph checks, TalkBack/
  VoiceOver traversal, and low-memory annual export.

## Risks and guardrails

| Risk | Guardrail |
| --- | --- |
| Preview/export mismatch | Render through one `RenderScene` contract and golden-test both paths. |
| Incorrect Myanmar dates | Keep calculations outside editable blocks; test historical and boundary dates. |
| Large image memory use | Store managed assets, decode to target size, render/export pages incrementally. |
| Excessive editor scope | Ship typed blocks and templates before arbitrary freeform features. |
| Data loss during rewrite | Use versioned documents, autosave, and non-destructive legacy import. |

## Completion criteria

Calendar Studio replaces the legacy generator only when a user can discover it
from Home, create and resume a project, reliably edit a calendar, export a
high-quality print/digital result, and migrate any supported legacy template
without losing its original data.
