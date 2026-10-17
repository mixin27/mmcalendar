# Calendar Studio template format (`.mmctemplate`)

A template is one page design that people can share and reuse. A project made
from a template gets one page per month (or one sheet for single-sheet designs).
Its month and year titles are rewritten for each page and the project's
language.

This document is the contract for anything that reads or writes these files,
including a future web gallery. The app's reader and writer are in
`packages/features/calendar_studio/lib/src/services/calendar_studio_template_bundle.dart`.

## The file

A `.mmctemplate` file is a zip archive (`application/zip`) holding:

| Entry | Required | Contents |
| --- | --- | --- |
| `manifest.json` | yes | What the file is, for listing without reading the design. |
| `template.json` | yes | The design. |
| `preview.png` | no | A PNG of the first page, about 600 px wide. |
| `assets/<id>.<ext>` | no | Images the design keeps (only when the author chose Keep photos). |

Readers ignore every other entry, as well as directories and any path that is
absolute or contains `..`. Asset names match `^assets/[A-Za-z0-9._-]+$`.
The app refuses files larger than 50 MB, measured both packed and unpacked.

## `manifest.json`

```json
{
  "format": "mmcalendar.studio.template",
  "version": 1,
  "createdAt": "2027-03-10T05:30:00.000Z",
  "name": "Gold wall",
  "author": "Aye",
  "canvas": { "width": 210, "height": 297 },
  "monthly": true,
  "preview": "preview.png",
  "assets": [
    { "id": "1712…", "file": "assets/1712….jpg", "name": "stupa.jpg", "width": 2048, "height": 1365 }
  ]
}
```

- `format` must be `mmcalendar.studio.template`. A file with any other value
  is not a template; for example, `.mmcstudio` project files use
  `mmcalendar.studio.project`.
- `version` is the version of the container. Readers reject a higher version
  than they know, with "made with a newer version of the app".
- `author` and `preview` are optional.
- `assets` lists each image. `id` is the id the design uses, and `file` is the
  zip entry. An image in the list but missing from the zip leaves an empty
  frame.

## `template.json`

```json
{
  "formatVersion": 1,
  "id": "9b2f…-…",
  "name": "Gold wall",
  "author": "Aye",
  "description": "…",
  "basePresetId": "jade-wall",
  "category": "Wall · A4 portrait",
  "monthly": true,
  "moods": ["Gold"],
  "palette": [4294967295, 4280295456],
  "canvas": { "width": 210, "height": 297, "safeInset": 0.04, "bleed": 0, "backgroundColor": 4294967295 },
  "blocks": [ … ],
  "createdAt": "2027-03-10T05:30:00.000Z",
  "updatedAt": "2027-03-10T05:30:00.000Z"
}
```

| Field | Notes |
| --- | --- |
| `formatVersion` | Version of this JSON. A higher value than the reader knows is rejected. |
| `id` | A UUID. Importing always assigns a new one, so a file never overwrites a template on the device. In the app, gallery and project ids are `user:<id>`. |
| `name` | Required, not blank. |
| `author`, `description` | Optional text. |
| `basePresetId` | The built-in preset the design started from (for example `jade-wall`), or `user:<id>` when it was saved from another user template. Shown as "Based on …". |
| `category` | Place and size, `"<Place> · <size>"`. The gallery files it under its first word: Wall, Desk, Social, Story or Annual. |
| `monthly` | `true` gives one page per month; `false` gives one sheet (year at a glance). |
| `moods` | Gallery mood chips and search words. |
| `palette` | ARGB colours as 32-bit integers, shown on the gallery card. |
| `canvas` | Page size in millimetres (or pixels for social sizes), with the safe inset as a fraction, bleed in millimetres, and the background as ARGB. |
| `blocks` | The page's blocks, encoded exactly as in `.mmcstudio` project files (`CalendarStudioDocumentCodec.encodeBlock`). |

### Blocks

Each block has `id`, `type`, `name`, `bounds` (`left`, `top`, `width`,
`height` as fractions of the page), `rotation`, `zIndex`, `visible`, `locked`,
`style` and `content`. The types are the `CalendarStudioBlockType` names:
`calendarGrid`, `text`, `image`, `logo`, `shape`, `decoration`,
`holidayLegend`, and the others the editor offers.

Calendar grids without `content.month` show each page's month. Mini grids
with an explicit `content.month` keep that month, as on year-at-a-glance
sheets.

Image blocks refer to images through `content.assetId`, and optionally
`originalAssetId` and `editBaseAssetId`. When the author left Keep photos
off, these keys are absent and the block is an empty frame.

### Bindings

A text block whose `content.binding` is set has its `content.text` rewritten
for every page. The text saved in the file is just an example (the month it
was saved from).

| `binding` | Myanmar | English | Both |
| --- | --- | --- | --- |
| `monthTitle` | ဇန်နဝါရီ | January | ဇန်နဝါရီ, with "January" as the subtitle when `bindingSubtitle` is true |
| `yearTitle` | ၂၀၂၈ | 2028 | 2028 |
| `monthYear` | ဇန်နဝါရီ ၂၀၂၈ | January 2028 | January 2028 |
| `eraLine` | The Myanmar months the Gregorian month spans, and their era years, in Myanmar (all languages) | | |

The binding keys:

- **`bindingSubtitle`:** when true, a month title also sets `content.subtitle`
  to the English month in "Both". Otherwise `subtitle` is removed.
- **`bindingUpper`:** when true, the text is written in capitals.

The language is the project's calendar language (`myanmar`, `english` or
`both`), not the device language. When saving, the app marks a text block as
bound if its text matches one of the forms above for the page's month and
year. English matches ignore case. The author can turn any of these back into
fixed text.

## Compatibility rules

- Writers add fields; they never change what an existing field means. Readers
  ignore fields they don't know.
- A change that older readers would get wrong raises `formatVersion` (for the
  JSON) or `version` (for the container).
- Keep files self-contained: no device paths, no URLs to fetch, and only the
  images listed in the manifest.
