# integrations_app_update

Remote-config-backed app update integration.

## Remote Config Keys

- `app_update_enabled` (`bool`): turns update checks on/off.
- `app_update_latest_build_number` (`int`): latest published build number.
- `app_update_latest_version` (`string`): latest human-readable app version.
- `app_update_min_supported_build_number` (`int`): minimum allowed build; if current build is lower, update is required.
- `app_update_force_title` (`string`): title for required-update dialog.
- `app_update_force_message` (`string`): message for required-update dialog.
- `app_update_optional_title` (`string`): title for optional-update dialog.
- `app_update_optional_message` (`string`): message for optional-update dialog.
- `app_update_release_notes` (`string`): optional release notes shown in dialogs.
- `app_update_android_url` (`string`): optional Android update URL override.
- `app_update_ios_url` (`string`): optional iOS update URL override.
- `app_update_web_url` (`string`): optional web update URL.

## Behavior

- Required update:
  - `currentBuild < app_update_min_supported_build_number`
- Optional update:
  - not required, and `currentBuild < app_update_latest_build_number`
- Up to date:
  - neither required nor optional conditions match

If `app_update_android_url` is empty, Android falls back to:

`https://play.google.com/store/apps/details?id=<playStoreId>`
