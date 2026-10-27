import type { Metadata } from "next";

import { Faq } from "@/components/faq";
import { NightHero } from "@/components/night-hero";
import { links } from "@/lib/site";
import { getDictionary, getLocale } from "../dictionaries";

export async function generateMetadata(): Promise<Metadata> {
  const [dict, locale] = await Promise.all([getDictionary(), getLocale()]);
  return {
    title: dict.supportPage.title,
    description: dict.supportPage.body,
    alternates: {
      canonical: `/${locale}/support`,
      languages: { my: "/my/support", en: "/en/support", "x-default": "/my/support" },
    },
  };
}

export default async function SupportPage() {
  const [dict, locale] = await Promise.all([getDictionary(), getLocale()]);
  const page = dict.supportPage;
  return (
    <>
      <NightHero dict={dict} locale={locale}>
        <h1 className="text-[clamp(34px,4.4vw,52px)] leading-[1.55] font-bold">{page.title}</h1>
        <p className="max-w-[680px] text-[17px] leading-[1.95] text-night-50">{page.body}</p>
      </NightHero>

      <section className="mx-auto grid max-w-[1000px] gap-5 px-4 pt-16 sm:grid-cols-2 sm:px-6">
        <a href={`mailto:${links.email}`} className="flex flex-col gap-2 rounded-3xl border bg-card p-7 no-underline hover:border-primary">
          <span className="text-xl font-bold text-foreground">{page.emailTitle}</span>
          <span className="text-muted-foreground">{page.emailBody}</span>
          <span className="mt-1 font-semibold break-all text-link">{links.email}</span>
        </a>
        <a href={links.issues} className="flex flex-col gap-2 rounded-3xl border bg-card p-7 no-underline hover:border-primary">
          <span className="text-xl font-bold text-foreground">{page.issuesTitle}</span>
          <span className="text-muted-foreground">{page.issuesBody}</span>
          <span className="mt-1 font-semibold break-all text-link">github.com/mixin27/mmcalendar/issues</span>
        </a>
      </section>

      <section className="mx-auto flex max-w-[820px] flex-col gap-7 px-4 pt-20 pb-24 sm:px-6">
        <h2 className="text-center text-[clamp(26px,3vw,34px)] leading-[1.6] font-bold">{dict.faq.title}</h2>
        <Faq items={dict.faq.items} />
      </section>
    </>
  );
}
