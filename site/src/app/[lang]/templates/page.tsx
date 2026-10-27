import type { Metadata } from "next";

import templates from "@/content/generated/templates.json";
import { NightHero } from "@/components/night-hero";
import { TemplateGallery } from "@/components/template-gallery";
import { fill } from "@/lib/site";
import { getDictionary, getLocale } from "../dictionaries";

/** The year the pack's projects were built for (tool/studio_templates). */
const year = templates[0]?.year ?? 2027;

export async function generateMetadata(): Promise<Metadata> {
  const [dict, locale] = await Promise.all([getDictionary(), getLocale()]);
  return {
    title: dict.templatesPage.title,
    description: fill(dict.templatesPage.description, { year }),
    alternates: {
      canonical: `/${locale}/templates`,
      languages: { my: "/my/templates", en: "/en/templates", "x-default": "/my/templates" },
    },
  };
}

export default async function TemplatesPage() {
  const [dict, locale] = await Promise.all([getDictionary(), getLocale()]);
  const page = dict.templatesPage;
  const sizes = { square: page.sizes.square, a4Portrait: page.sizes.a4Portrait, a4Landscape: page.sizes.a4Landscape };
  return (
    <>
      <NightHero dict={dict} locale={locale}>
        <span lang="en" className="text-sm font-bold tracking-wide text-gold uppercase">
          {page.eyebrow}
        </span>
        <h1 className="text-[clamp(34px,4.4vw,52px)] leading-[1.55] font-bold">{page.heading}</h1>
        <p className="max-w-[680px] text-[17px] leading-[1.95] text-night-50">{page.body}</p>
      </NightHero>

      <section className="mx-auto max-w-[1200px] px-4 pt-10 pb-6 sm:px-6">
        <TemplateGallery
          designs={templates.map((design) => ({
            id: design.id,
            name: design.name,
            topic: design.topic,
            size: sizes[design.format as keyof typeof sizes] ?? design.format,
            blurb: page.designs[design.id as keyof typeof page.designs] ?? "",
            preview: design.preview,
            previewWidth: design.previewWidth,
            previewHeight: design.previewHeight,
            project: design.project,
            template: design.template,
          }))}
          topics={dict.topics}
          labels={{
            filter: page.filterLabel,
            project: fill(page.downloadProject, { year }),
            template: page.downloadTemplate,
          }}
        />
      </section>

      <section className="mx-auto flex max-w-[1200px] flex-col gap-7 px-4 pt-16 pb-24 sm:px-6">
        <h2 className="text-[clamp(26px,3vw,34px)] leading-[1.6] font-bold">{page.stepsTitle}</h2>
        <ol className="grid grid-cols-[repeat(auto-fit,minmax(min(100%,300px),1fr))] gap-4">
          {page.steps.map((step, index) => (
            <li key={step.title} className="flex gap-4 rounded-[20px] bg-panel p-5">
              <span
                aria-hidden="true"
                className="flex size-9 flex-none items-center justify-center rounded-full bg-night-800 font-bold text-gold"
              >
                {index + 1}
              </span>
              <span className="flex flex-col gap-1">
                <span className="text-base font-bold">{step.title}</span>
                <span className="text-sm leading-[1.85] text-muted-foreground">{step.body}</span>
              </span>
            </li>
          ))}
        </ol>
      </section>
    </>
  );
}
