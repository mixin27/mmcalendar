# Myanmar Calendar website

The landing site for Myanmar Calendar, in Myanmar (`/my`, the default) and English (`/en`):

- the landing page;
- the Studio templates gallery, with downloads;
- What's new, built from `CHANGELOG.md`;
- privacy and support.

It uses Next.js 16 (App Router, Cache Components), React 19, Tailwind CSS 4 and shadcn/ui, with pnpm.

```sh
pnpm install
pnpm dev     # http://localhost:3000 → redirects to /my or /en
pnpm build   # every page is prerendered
```

## Content comes from the repo

`scripts/sync-content.mjs` runs before `dev` and `build`. It copies or derives the following, so the site can't drift from the app:

| From | To |
|---|---|
| `screenshots/app/*.png` | `public/content/app/` |
| `docs/design/home-widgets-v4/built-*.jpg` | `public/content/widgets/` |
| `docs/studio-templates/**` | `public/content/templates/`, plus `src/content/generated/templates.json` |
| `apps/myanmar_calendar/assets/branding/app_icon_1024.png` | `public/content/brand/icon.png` |
| `CHANGELOG.md` | `src/content/generated/releases.json` |
| `AppConstants.privacyPolicyMarkdown` | `src/content/generated/privacy.md` |

Generated files are gitignored. `src/content/languages.json` (the same date in the six calendar languages) is committed. It comes from `packages/shared/core/tool/landing_language_samples.dart`:

```sh
cd packages/shared/core
dart run tool/landing_language_samples.dart ../../../site/src/content/languages.json
```

## Copy

All text is in `src/app/[lang]/dictionaries/{my,en}.json`. Add a page by adding its strings to both files.

## Deploying on Vercel

1. Import the repository and set **Root Directory** to `site`. Vercel detects Next.js and pnpm.
2. **Environment variables:**
   - `NEXT_PUBLIC_SITE_URL`: the site's address, e.g. `https://calendar.kyawzayartun.com`. Used for canonical URLs, the sitemap and share images.
   - `NEXT_PUBLIC_WEB_APP_URL`: optional. The Flutter web app on Netlify. The "Open the web app" links appear only when it is set.
3. **Domain:** add the subdomain in Vercel, then add a `CNAME` record for it pointing to `cname.vercel-dns.com` at your DNS provider.
4. **Builds:** `vercel.json` has an `ignoreCommand` that skips a build unless the site, or something it copies in (screenshots, templates, widgets, changelog, brand icon, privacy text), changed in the last commit.
