import type { Metadata } from "next";
import { marked } from "marked";

import releases from "@/content/generated/releases.json";
import { NightHero } from "@/components/night-hero";
import { fill } from "@/lib/site";
import { getDictionary, getLocale } from "../dictionaries";

export async function generateMetadata(): Promise<Metadata> {
  const [dict, locale] = await Promise.all([getDictionary(), getLocale()]);
  return {
    title: dict.whatsNewPage.title,
    description: dict.whatsNewPage.body,
    alternates: {
      canonical: `/${locale}/whats-new`,
      languages: { my: "/my/whats-new", en: "/en/whats-new", "x-default": "/my/whats-new" },
    },
  };
}

function formatDate(date: string, locale: string) {
  return new Intl.DateTimeFormat(locale === "my" ? "my-MM" : "en-GB", {
    day: "numeric",
    month: "long",
    year: "numeric",
    timeZone: "UTC",
  }).format(new Date(`${date}T00:00:00Z`));
}

export default async function WhatsNewPage() {
  const [dict, locale] = await Promise.all([getDictionary(), getLocale()]);
  return (
    <>
      <NightHero dict={dict} locale={locale}>
        <span lang="en" className="text-sm font-bold tracking-wide text-gold uppercase">
          {dict.whatsNewPage.eyebrow}
        </span>
        <h1 className="text-[clamp(34px,4.4vw,52px)] leading-[1.55] font-bold">{dict.whatsNewPage.title}</h1>
        <p className="max-w-[680px] text-[17px] leading-[1.95] text-night-50">{dict.whatsNewPage.body}</p>
      </NightHero>

      <ol className="mx-auto flex max-w-[820px] flex-col gap-6 px-4 py-16 sm:px-6">
        {releases.map((release) => (
          <li key={release.version} className="rounded-3xl border bg-card p-6 sm:p-8">
            <div className="flex flex-wrap items-baseline justify-between gap-x-4 gap-y-1">
              <h2 className="text-2xl font-bold">{fill(dict.whatsNewPage.version, { version: release.version })}</h2>
              <time dateTime={release.date} className="text-sm text-muted-foreground">
                {formatDate(release.date, locale)}
              </time>
            </div>
            <ul lang="en" className="mt-4 flex list-disc flex-col gap-2 pl-5 text-[15px] leading-[1.8] marker:text-gold">
              {release.notes.map((note, index) => (
                <li
                  key={index}
                  className={note.nested ? "ml-5 list-[circle]" : ""}
                  // CHANGELOG bullets carry inline code and emphasis.
                  dangerouslySetInnerHTML={{ __html: marked.parseInline(note.text, { async: false }) }}
                />
              ))}
            </ul>
          </li>
        ))}
      </ol>
    </>
  );
}
