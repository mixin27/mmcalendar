# Web app deploy (Vercel)

The Flutter web app (`apps/myanmar_calendar`) is built in GitHub Actions and
uploaded to Vercel as static files. Vercel never builds it: it has no Flutter,
no `firebase_options.dart` and no `build_runner`.

- Workflow: `.github/workflows/web_deploy.yml`. It runs only when a release tag
  (`v*`, e.g. `v2.7.1`) is pushed, never on pushes or pull requests. To redeploy,
  run it by hand from the Actions tab (Run workflow) and pick the tag.
- Routing and caching: `apps/myanmar_calendar/web/vercel.json`, which
  `flutter build web` copies into `build/web`.
  - Every path that isn't a file is rewritten to `index.html`.
  - `index.html`, `flutter_bootstrap.js`, `flutter_service_worker.js`,
    `version.json` and `manifest.json` are sent with `no-cache`, so a new
    release shows up on the next visit.
- The website (`site/`) is a separate Vercel project that builds from Git; see
  `site/vercel.json`.

## Setup

1. Create a Vercel project **without connecting the Git repository**, for example
   `npx vercel project add myanmar-calendar-web`. If the repository is connected,
   Vercel tries to build Flutter on every push and fails.
2. In the project settings, set Framework Preset to "Other", and leave the build
   command, install command and output directory empty.
3. Get the ids: run `npx vercel link` in an empty folder, pick the project, and
   read `orgId` and `projectId` from `.vercel/project.json`. Create a token at
   <https://vercel.com/account/tokens>.
4. Add the GitHub Actions secrets `VERCEL_TOKEN`, `VERCEL_ORG_ID` and
   `VERCEL_PROJECT_ID`. The build also needs `FIREBASE_OPTIONS_BASE64`.
5. Add the domain in the Vercel project.

When the web app's URL changes:

- Set `NEXT_PUBLIC_WEB_APP_URL` in the site's Vercel project and redeploy the
  site. Its "Open the web app" links use it.
- In Firebase, add the domain under Authentication → Settings → Authorized
  domains. If the web API key has HTTP-referrer restrictions in Google Cloud,
  add the domain there too.
- In OneSignal, update the web push site URL. Subscriptions belong to an origin,
  so people subscribed on the old domain need to subscribe again.

## Not used

- COOP/COEP headers. drift picks a slower storage option without them (see
  `DriftWebOptions` in `app_database.dart`), and they could block third-party
  scripts.
