# Calendar Generation Feature Blueprint

## Objectives

- Generate calendar output for:
  - selected month
  - selected year (12-month pack)
- Export targets:
  - PDF (print-ready)
  - image (PNG, optional JPG)
- Support visual customization:
  - background/foreground colors
  - optional per-month hero/background image
- Provide in-app preview matching exported output.

## Product Scope

### Phase 1 (MVP)

- Month-only generation.
- In-app preview.
- PDF export.
- Print flow integration.
- Basic template customization:
  - theme colors
  - one optional background image.

### Phase 2

- Full-year generation (single PDF with 12 pages).
- Image export:
  - one image per month
  - ZIP bundle for year export.
- Per-month image assignment.

### Phase 3

- Multiple layout presets.
- Optional branding (title/footer/logo).
- Saved template presets.

## Non-Goals (Initial)

- Free-form canvas editor (drag/drop arbitrary blocks).
- Cloud rendering backend.
- User-to-user template marketplace.

## Architecture Direction

Follow a single-source render model that feeds both preview and export pipelines.

```
Calendar Data + Settings + Template
            ->
      CalendarPageModel
            ->
  [Preview Widget] + [PDF Renderer] + [Image Renderer]
```

This avoids output drift between what users preview and what they export.

## Proposed Package Layout

Add a dedicated feature package:

```text
packages/features/calendar_generation/
  lib/
    calendar_generation.dart
    src/
      domain/
        entities/
        repositories/
        usecases/
      data/
        datasources/
        repositories/
      presentation/
        bloc/
        pages/
        widgets/
      rendering/
        page_model_builder.dart
        preview/
        pdf/
        image/
```

Reason:

- Keeps export concerns isolated from existing calendar browsing UX.
- Enables future reuse for web/share/automation exports.

## Core Domain Model

### `CalendarGenerationRequest`

- `mode`: `month` | `year`
- `year`
- `month` (required when `mode == month`)
- `language`
- `useDeviceTimezone`
- `sasanaYearType`
- `paperSize`
- `orientation`
- `outputFormats`: `pdf`, `png`, `jpg`
- `templateId`
- `customization`

### `CalendarCustomization`

- `backgroundColor`
- `foregroundColor`
- `accentColor`
- `monthImage` (single for phase 1)
- `monthImagesByMonth` (phase 2)
- `showHolidays`
- `showAstrology`
- `showMyanmarDates`
- `showWesternDates`

### `CalendarPageModel`

- Header:
  - year/month labels
  - locale text
- Grid:
  - weekday labels
  - 6x7 cells with both date systems
  - holiday/astro markers
- Decorations:
  - background style
  - image overlay metadata
- Footer:
  - generated timestamp/version/template.

### `GenerationArtifact`

- `type`: `pdf` | `image`
- `filePath`
- `bytes` (optional, for share-only flows)
- metadata:
  - page count
  - dimensions
  - createdAt.

## Rendering Strategy

## 1) Page Model Builder

`CalendarPageModelBuilder` maps existing date sources to export-ready page data.

Inputs:

- `myanmar_calendar_dart` data (`CompleteDate`, month grid)
- settings (`CalendarConfig`, language, show flags)
- template customization.

Output:

- list of `CalendarPageModel` (1 or 12).

## 2) Preview Renderer (Flutter)

Widget tree consumes `CalendarPageModel`:

- deterministic layout dimensions
- page frame matching paper ratio
- supports page swiping for year mode.

## 3) PDF Renderer

Use `pdf` and `printing` packages.

- Vector text and shapes for print quality.
- Embedded Myanmar-capable fonts.
- Image placement with fit modes (`cover`, `contain`).
- A4/Letter support.
- Margin presets.

## 4) Image Renderer

Use off-screen Flutter render:

- `RepaintBoundary` per page
- target pixel size by print DPI profile.

Profiles:

- `screen`: ~150 DPI
- `print`: 300 DPI.

## Printing Readiness Requirements

- Supported sizes:
  - A4
  - Letter
- Margins:
  - default safe margin
  - optional bleed profile.
- Color:
  - RGB export for app
  - rely on printer conversion (phase 1).
- Typography:
  - embed fonts in PDF
  - ensure Myanmar glyph coverage.

## UI/UX Flow

`Calendar Generation` entry page:

1. Select mode (`Month` or `Year`).
2. Select year/month.
3. Select template.
4. Customize colors and image.
5. Preview.
6. Export:
  - PDF
  - Image
  - Print
  - Share.

## Integration With Existing App

Reuse:

- Existing calendar data generation and localization utilities.
- Existing settings toggles (show holidays, astrology, date visibility).
- Existing timezone policy:
  - `use_device_timezone` setting
  - locked `calendarType = British`.

Add:

- New route: `RoutePaths.calendarGeneration`
- New feature DI initialization.

## Storage Plan

Local persistence (app settings table or dedicated generation settings):

- last used generation mode
- last used paper size/orientation
- last used template
- last used customization values
- recent month image URIs.

Phase 2+:

- save named templates in local DB.

## Dependencies

Add in `packages/features/calendar_generation/pubspec.yaml`:

- `pdf`
- `printing`
- `archive` (for year image ZIP)
- `path_provider`
- `image_picker` (if selecting photos in feature scope)

## Testing Strategy

### Unit Tests

- `CalendarPageModelBuilder`:
  - month/year correctness
  - locale + timezone behavior
  - holiday visibility flags.
- Template merge logic.

### Golden Tests

- Preview widget snapshots for key templates/languages.

### PDF Snapshot Tests

- smoke test page count and non-empty bytes
- basic text presence checks for month labels.

### Integration Tests

- full flow:
  - choose month
  - preview
  - export pdf
  - print/share invocation path.

## Performance Constraints

- Year generation should be cancellable.
- Run heavy generation in background isolate where possible.
- Cache intermediate month page models during same session.
- Avoid decoding large source images repeatedly.

## Risks and Mitigations

- Font rendering mismatch between preview/PDF:
  - use same font families and verify glyph coverage early.
- Large memory usage for image export:
  - per-page streaming and immediate flush to file.
- Layout drift across preview/export:
  - centralize constants in shared layout spec.

## Delivery Checklist

### Milestone A (Month PDF + Preview)

- Create package `calendar_generation`.
- Build `CalendarPageModel` and builder.
- Build preview page.
- Implement PDF export and print.
- Add route and settings persistence.

### Milestone B (Year + Image Export)

- Add year generation mode.
- Add image export with per-page files.
- Add ZIP output for year images.

### Milestone C (Template Presets)

- Add 2-3 built-in templates.
- Add save/load custom template presets.

## Recommended Build Order (Code Tasks)

1. Scaffold `calendar_generation` package and DI.
2. Implement domain entities and usecases.
3. Implement `CalendarPageModelBuilder` using existing calendar data APIs.
4. Implement preview widget and page navigation.
5. Implement PDF renderer + print action.
6. Wire export/share from UI.
7. Add tests.

