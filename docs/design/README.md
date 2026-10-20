# Design boards

Self-contained HTML pages that record why the app looks the way it does.
Open any of them in a browser. They show the designs as decided; the app
is the source of truth where the two differ.

| Board | What it covers |
| --- | --- |
| [app-design-v4.html](app-design-v4.html) | The current app design: onboarding, What's new and Holidays |
| [calendar-grids-v4.html](calendar-grids-v4.html) | Home calendar grid layouts |
| [grid-designs.html](grid-designs.html) | The newer grids: Almanac, Myanmar months, Focus week, Auspice, Moon band, Hero today, Week ribbons |
| [calendar-grid-themes.html](calendar-grid-themes.html) | The twelve grid themes |
| [calendar-studio-v3.html](calendar-studio-v3.html) | Calendar Studio editor tools |
| [home-widgets-v4.html](home-widgets-v4.html) | Home-screen widgets on iOS and Android, before and after (images in `home-widgets-v4/`) |
| [app-icons.html](app-icons.html) | The Moon page app icon and its variants |

## Inputs to code

These two are read by `packages/features/calendar_studio/tool/generate_preset_specs.py`
to build Calendar Studio's preset specs, so keep them in step with
`calendar_studio_preset_specs.dart`:

- [calendar-studio-theme-presets.html](calendar-studio-theme-presets.html) (Vol. 1)
- [calendar-studio-theme-presets-2.html](calendar-studio-theme-presets-2.html) (Vol. 2)
