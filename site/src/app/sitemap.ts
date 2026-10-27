import type { MetadataRoute } from "next";

import { siteUrl } from "@/lib/site";

const pages = ["", "/templates", "/whats-new", "/support", "/privacy"];

export default function sitemap(): MetadataRoute.Sitemap {
  return pages.flatMap((page) =>
    ["my", "en"].map((locale) => ({
      url: `${siteUrl}/${locale}${page}`,
      alternates: {
        languages: { my: `${siteUrl}/my${page}`, en: `${siteUrl}/en${page}` },
      },
      changeFrequency: page === "/whats-new" ? ("monthly" as const) : ("yearly" as const),
      priority: page === "" ? 1 : 0.6,
    })),
  );
}
