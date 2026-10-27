import { NextResponse, type NextRequest } from "next/server";

const locales = ["my", "en"];

/** Myanmar unless the browser asks for English and not Myanmar. */
function preferredLocale(request: NextRequest) {
  const accept = (request.headers.get("accept-language") ?? "").toLowerCase();
  const wanted = accept.split(",").map((part) => part.split(";")[0].trim());
  if (wanted.some((tag) => tag === "my" || tag.startsWith("my-"))) return "my";
  if (wanted[0]?.startsWith("en")) return "en";
  return "my";
}

/** Sends paths without a locale (`/`, `/templates`) to `/my/…` or `/en/…`. */
export function proxy(request: NextRequest) {
  const { pathname } = request.nextUrl;
  const hasLocale = locales.some((locale) => pathname === `/${locale}` || pathname.startsWith(`/${locale}/`));
  if (hasLocale) return;
  request.nextUrl.pathname = `/${preferredLocale(request)}${pathname === "/" ? "" : pathname}`;
  return NextResponse.redirect(request.nextUrl);
}

export const config = {
  // Not for Next.js internals, synced content, metadata files or anything with an extension.
  matcher: ["/((?!_next|content|sitemap.xml|robots.txt|.*\\..*).*)"],
};
