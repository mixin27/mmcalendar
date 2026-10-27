import { readFile } from "node:fs/promises";
import { join } from "node:path";

import type { Metadata } from "next";
import { marked } from "marked";

import { NightHero } from "@/components/night-hero";
import { getDictionary, getLocale } from "../dictionaries";

export async function generateMetadata(): Promise<Metadata> {
  const [dict, locale] = await Promise.all([getDictionary(), getLocale()]);
  return {
    title: dict.privacyPage.title,
    description: dict.privacyPage.description,
    alternates: {
      canonical: `/${locale}/privacy`,
      languages: { my: "/my/privacy", en: "/en/privacy", "x-default": "/my/privacy" },
    },
  };
}

/**
 * The same policy the app shows (AppConstants.privacyPolicyMarkdown), copied
 * in by scripts/sync-content.mjs. Its own "# Privacy Policy" heading gives way
 * to the page heading. Cached: it only changes with a new build.
 */
async function policyHtml() {
  "use cache";
  const markdown = await readFile(join(process.cwd(), "src/content/generated/privacy.md"), "utf8");
  return marked.parse(markdown.replace(/^# .*\n/, ""), { async: false });
}

export default async function PrivacyPage() {
  const [dict, locale, html] = await Promise.all([getDictionary(), getLocale(), policyHtml()]);
  return (
    <>
      <NightHero dict={dict} locale={locale}>
        <h1 className="text-[clamp(34px,4.4vw,52px)] leading-[1.55] font-bold">{dict.privacyPage.title}</h1>
        <p className="max-w-[680px] text-[17px] leading-[1.95] text-night-50">{dict.privacyPage.description}</p>
      </NightHero>
      <article
        lang="en"
        className="prose-policy mx-auto max-w-[760px] px-4 py-16 text-[16px] leading-[1.8] sm:px-6"
        dangerouslySetInnerHTML={{ __html: html }}
      />
    </>
  );
}
