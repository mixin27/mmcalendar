import type { Metadata } from "next";
import Link from "next/link";

import { NightHero } from "@/components/night-hero";
import { links } from "@/lib/site";
import { getDictionary, getLocale } from "../dictionaries";

export async function generateMetadata(): Promise<Metadata> {
  const [dict, locale] = await Promise.all([getDictionary(), getLocale()]);
  return {
    title: dict.deleteDataPage.title,
    description: dict.deleteDataPage.description,
    alternates: {
      canonical: `/${locale}/delete-data`,
      languages: { my: "/my/delete-data", en: "/en/delete-data", "x-default": "/my/delete-data" },
    },
  };
}

/**
 * The data deletion page Google Play's Data safety form links to: what to
 * delete on the device, and how to ask for the Firebase data to be deleted.
 * It must agree with the privacy policy (AppConstants.privacyPolicyMarkdown).
 */
export default async function DeleteDataPage() {
  const [dict, locale] = await Promise.all([getDictionary(), getLocale()]);
  const page = dict.deleteDataPage;
  const mailto = `mailto:${links.email}?subject=${encodeURIComponent(page.emailSubject)}`;
  const card = "flex flex-col gap-3 rounded-3xl border bg-card p-7";
  const heading = "text-xl font-bold text-foreground";
  const list = "flex list-disc flex-col gap-2 pl-5 text-[15px] leading-[1.8] text-muted-foreground marker:text-gold";

  return (
    <>
      <NightHero dict={dict} locale={locale}>
        <h1 className="text-[clamp(34px,4.4vw,52px)] leading-[1.55] font-bold">{page.title}</h1>
        <p className="max-w-[680px] text-[17px] leading-[1.95] text-night-50">{page.description}</p>
        <p className="text-sm text-night-100">{page.appName}</p>
      </NightHero>

      <div className="mx-auto flex max-w-[820px] flex-col gap-5 px-4 py-16 sm:px-6">
        <section id="device" className={card}>
          <h2 className={heading}>{page.deviceTitle}</h2>
          <p className="text-muted-foreground">{page.deviceBody}</p>
          <ul className={list}>
            {page.deviceSteps.map((step) => (
              <li key={step}>{step}</li>
            ))}
          </ul>
        </section>

        <section id="stop" className={card}>
          <h2 className={heading}>{page.stopTitle}</h2>
          <p className="text-muted-foreground">{page.stopBody}</p>
        </section>

        <section id="firebase" className={card}>
          <h2 className={heading}>{page.firebaseTitle}</h2>
          <p className="text-muted-foreground">{page.firebaseBody}</p>
          <ol className={list.replace("list-disc", "list-decimal")}>
            {page.firebaseSteps.map((step) => (
              <li key={step}>{step}</li>
            ))}
          </ol>
          <a
            href={mailto}
            className="mt-2 inline-flex w-fit items-center rounded-full bg-primary px-5 py-2.5 font-semibold text-primary-foreground no-underline hover:opacity-90"
          >
            {page.emailButton}
          </a>
          <span className="font-semibold break-all text-link">{links.email}</span>
        </section>

        <section id="what" className={card}>
          <h2 className={heading}>{page.deletedTitle}</h2>
          <ul className={list}>
            {page.deleted.map((line) => (
              <li key={line}>{line}</li>
            ))}
          </ul>
        </section>

        <Link href={`/${locale}/privacy`} className="self-center font-semibold text-link">
          {page.policy}
        </Link>
      </div>
    </>
  );
}
