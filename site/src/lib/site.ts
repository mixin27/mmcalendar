/** Where the site lives; set NEXT_PUBLIC_SITE_URL on Vercel to the real domain. */
export const siteUrl = (process.env.NEXT_PUBLIC_SITE_URL ?? "https://calendar.kyawzayartun.com").replace(/\/$/, "");

/** The Flutter web app; the "Open the web app" links hide while it's unset. */
export const webAppUrl = process.env.NEXT_PUBLIC_WEB_APP_URL ?? null;

export const links = {
  appStore: "https://apps.apple.com/us/app/myanmar-calendar-pyatkadain/id6811349564",
  appStoreId: "6811349564",
  googlePlay: "https://play.google.com/store/apps/details?id=dev.mixin27.mmcalendar",
  github: "https://github.com/mixin27/mmcalendar",
  issues: "https://github.com/mixin27/mmcalendar/issues",
  email: "kyawzayartun.contact@gmail.com",
  author: "Kyaw Zayar Tun",
} as const;

/** Screens and photos copied in by scripts/sync-content.mjs. */
export const content = (path: string) => `/content/${path}`;

/** Fills `{name}` holes in dictionary strings. */
export function fill(text: string, values: Record<string, string | number>) {
  return text.replace(/\{(\w+)\}/g, (hole, key: string) => String(values[key] ?? hole));
}
