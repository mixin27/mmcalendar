# Studio template pack generator

Builds the shareable Calendar Studio designs in
[`docs/studio-templates`](../../../../../docs/studio-templates): for each
design a year project (`.mmcstudio`, a cover and twelve months), a reusable
template (`.mmctemplate`, one month design for any year) and a contact sheet
of every page, plus the gallery README.

```sh
cd packages/features/calendar_studio
flutter test tool/studio_templates/build_studio_templates_test.dart
```

- `STUDIO_TEMPLATES_YEAR=2028` builds the projects for another year
  (templates already work for any year).
- `STUDIO_TEMPLATES_OUT=/some/folder` writes somewhere else, e.g. to review
  changes before replacing the committed files.

It runs as a test because rendering needs Flutter's engine, but it lives in
`tool/`, so the package's own `flutter test` never runs it. Every file is
read back with Studio's own readers, and each template is checked to make a
calendar for the following year.

## Files

- `page_builder.dart`: block helpers (titles, photos, shapes, motifs, lists,
  grid, legend) that write Studio's document JSON. Bounds are fractions of
  the page; sizes are design units (600 × 600 square, 595 × 842 A4
  portrait, 842 × 595 A4 landscape); rotation is in degrees.
- `design.dart`: the `StudioTemplateDesign` interface.
- `designs/`: the designs, by topic.
- `build_studio_templates_test.dart`: builds, checks and writes everything.

## Adding a design

1. Add a class implementing `StudioTemplateDesign` in `designs/`: a cover,
   a `month` layout (keep month-specific words behind `context.template`,
   since the template repeats one page for every month), a palette in
   Studio's colour roles and the closest built-in preset as `basePresetId`.
2. Use `monthTitle` and `yearText` for titles, so Studio rewrites them for
   each month, year and calendar language.
3. Add it to `designs` in `build_studio_templates_test.dart`, run the
   builder, and check its contact sheet.

Photo frames stay empty in the files; previews use soft gradients instead.
Studio blocks export while an image frame is empty; logo frames are fine.
