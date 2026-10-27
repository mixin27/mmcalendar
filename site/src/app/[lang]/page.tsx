import Image from "next/image";
import Link from "next/link";

import languages from "@/content/languages.json";
import templates from "@/content/generated/templates.json";
import { Faq } from "@/components/faq";
import { Moon, Stars } from "@/components/night-sky";
import { Phone } from "@/components/phone";
import { SiteHeader } from "@/components/site-header";
import { StoreButtons } from "@/components/store-buttons";
import { content, fill, links, siteUrl, webAppUrl } from "@/lib/site";
import { getDictionary, getLocale } from "./dictionaries";

/** One template per topic for the Studio band. */
const showcase = ["love-letters", "family-album", "good-times", "clean-corporate"];

export default async function Home() {
  const [dict, locale] = await Promise.all([getDictionary(), getLocale()]);
  const home = `/${locale}`;
  const featured = showcase.map((id) => templates.find((design) => design.id === id)!);

  const jsonLd = {
    "@context": "https://schema.org",
    "@type": "MobileApplication",
    name: dict.meta.siteName,
    alternateName: locale === "my" ? "Myanmar Calendar" : "မြန်မာ ပြက္ခဒိန်",
    description: dict.meta.description,
    url: `${siteUrl}${home}`,
    operatingSystem: "Android, iOS, Web",
    applicationCategory: "LifestyleApplication",
    offers: { "@type": "Offer", price: "0", priceCurrency: "USD" },
    downloadUrl: [links.appStore, links.googlePlay],
    author: { "@type": "Person", name: links.author },
  };

  return (
    <>
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(jsonLd).replace(/</g, "\\u003c") }}
      />

      {/* Hero */}
      <section className="night relative overflow-hidden">
        <Stars count={22} seed={3} />
        <SiteHeader dict={dict} locale={locale} />
        <div
          id="content"
          className="relative mx-auto grid max-w-[1200px] items-center gap-14 px-4 pt-12 pb-24 sm:px-6 lg:grid-cols-2"
        >
          <div className="flex flex-col gap-5">
            <span className="self-start rounded-full border border-gold/45 px-3.5 py-1.5 text-[13px] font-semibold text-gold">
              {dict.hero.badge}
            </span>
            <h1 lang="my" className="font-myanmar text-[clamp(44px,6vw,72px)] leading-[1.45] font-bold tracking-tight">
              မြန်မာ ပြက္ခဒိန်
            </h1>
            <p lang="en" className="-mt-2.5 text-[22px] font-medium text-night-100">
              {dict.hero.tagline}
            </p>
            <p className="max-w-[520px] text-[17px] leading-[1.95] text-night-50">{dict.hero.body}</p>
            <div id="download" className="mt-1.5 scroll-mt-6">
              <StoreButtons dict={dict} />
            </div>
            {webAppUrl && (
              <a href={webAppUrl} className="self-start text-[15px] font-semibold text-gold">
                {dict.hero.openWeb}
              </a>
            )}
          </div>

          <div className="relative flex justify-center py-6">
            <Moon className="absolute -top-1.5 right-[8%] size-32 sm:size-[170px]" />
            <Phone src="01_home.png" alt={dict.hero.screenshotAlt} className="relative w-[min(300px,72vw)]" priority />
            <div className="absolute bottom-16 left-0 flex max-w-[280px] items-center gap-3 rounded-2xl bg-[#f7f9fe]/95 px-4 py-3 text-night-800 shadow-[0_16px_40px_rgb(5_10_30/0.35)] sm:left-[2%]">
              <span aria-hidden="true" className="moon size-[30px] flex-none [animation:none]" />
              <span className="flex flex-col">
                <span className="text-xs text-[#5b6478]">{dict.hero.sampleDate}</span>
                <span className="text-sm font-bold">{dict.hero.sampleValue}</span>
              </span>
            </div>
          </div>
        </div>
      </section>

      {/* Highlights */}
      <section aria-label={dict.highlights.label} className="border-b">
        <ul className="mx-auto grid max-w-[1200px] grid-cols-[repeat(auto-fit,minmax(min(100%,200px),1fr))] gap-x-6 gap-y-4 px-4 py-7 sm:px-6">
          {dict.highlights.items.map((item) => (
            <li key={item} className="flex items-center gap-3 text-[15px] font-semibold">
              <span aria-hidden="true" className="size-2.5 flex-none rounded-full bg-gold shadow-[0_0_0_4px_rgb(244_197_98/0.22)]" />
              {item}
            </li>
          ))}
        </ul>
      </section>

      {/* Features */}
      <section id="features" className="mx-auto flex max-w-[1200px] scroll-mt-6 flex-col gap-28 px-4 pt-24 pb-10 sm:px-6">
        <div className="flex flex-col items-center gap-3 text-center">
          <span className="text-sm font-bold tracking-wide text-link">{dict.features.eyebrow}</span>
          <h2 className="text-[clamp(30px,3.6vw,44px)] leading-[1.6] font-bold">{dict.features.title}</h2>
          <p className="max-w-[620px] text-[17px] text-muted-foreground">{dict.features.body}</p>
        </div>

        {dict.features.items.map((feature, index) => (
          <article key={feature.title} className="grid items-center gap-x-[72px] gap-y-12 lg:grid-cols-2">
            <div className={`flex flex-col gap-4 ${index % 2 ? "lg:order-2" : ""}`}>
              <span className="text-sm font-bold text-link">{feature.eyebrow}</span>
              <h3 className="text-[clamp(26px,3vw,36px)] leading-[1.6] font-bold">{feature.title}</h3>
              <p className="text-[17px] leading-[1.95] text-muted-foreground">{feature.body}</p>
              <ul className="mt-1 flex flex-wrap gap-2">
                {feature.chips.map((chip) => (
                  <li key={chip} className="rounded-full bg-chip px-3 py-1.5 text-[13px] font-semibold text-chip-foreground">
                    {chip}
                  </li>
                ))}
              </ul>
            </div>
            <div className="flex justify-center gap-5 rounded-[32px] bg-panel px-4 py-10">
              {feature.images.map((image) => (
                <Phone
                  key={image.src}
                  src={image.src}
                  alt={image.alt}
                  className={feature.images.length > 1 ? "w-[min(230px,42%)]" : "w-[min(280px,70%)]"}
                />
              ))}
            </div>
          </article>
        ))}

        <article className="flex flex-col items-center gap-7 text-center">
          <span className="text-sm font-bold text-link">{dict.features.widgets.eyebrow}</span>
          <h3 className="text-[clamp(26px,3vw,36px)] leading-[1.6] font-bold">{dict.features.widgets.title}</h3>
          <p className="max-w-[620px] text-[17px] leading-[1.95] text-muted-foreground">{dict.features.widgets.body}</p>
          <div className="flex w-full flex-wrap items-center justify-center gap-6 rounded-[32px] bg-panel p-8">
            <Image
              src={content("widgets/built-ios-today-large.jpg")}
              alt={dict.features.widgets.iosAlt}
              width={603}
              height={560}
              sizes="300px"
              className="h-auto w-[300px] max-w-full rounded-3xl"
            />
            <Image
              src={content("widgets/built-android-light.jpg")}
              alt={dict.features.widgets.androidAlt}
              width={1620}
              height={560}
              sizes="(max-width: 700px) 100vw, 620px"
              className="h-auto w-[620px] max-w-full rounded-3xl"
            />
          </div>
        </article>
      </section>

      {/* Calendar Studio */}
      <section id="studio" className="relative mt-20 scroll-mt-6 overflow-hidden bg-[linear-gradient(170deg,#0d1328_0%,#14203d_60%,#1e3a73_100%)] text-[#f7f9fe]">
        <Moon className="absolute top-16 -right-16 size-[220px] opacity-90" />
        <div className="relative mx-auto flex max-w-[1200px] flex-col gap-12 px-4 py-24 sm:px-6">
          <div className="grid items-center gap-x-[72px] gap-y-12 lg:grid-cols-2">
            <div className="flex flex-col gap-4">
              <span className="text-sm font-bold tracking-wide text-gold">{dict.studio.eyebrow}</span>
              <h2 className="text-[clamp(30px,3.6vw,44px)] leading-[1.6] font-bold">{dict.studio.title}</h2>
              <p className="text-[17px] leading-[1.95] text-night-50">{dict.studio.body}</p>
              <Link
                href={`${home}/templates`}
                className="mt-1.5 self-start rounded-full bg-gold px-5 py-3 text-[15px] font-bold text-night-800 no-underline hover:bg-[#f7d27e]"
              >
                {fill(dict.studio.cta, { count: templates.length })}
              </Link>
            </div>
            <div className="flex justify-center">
              <Phone src="06_studio.png" alt={dict.studio.screenshotAlt} className="w-[min(290px,70vw)]" />
            </div>
          </div>
          <ul className="grid grid-cols-[repeat(auto-fit,minmax(min(100%,250px),1fr))] gap-5">
            {featured.map((design) => (
              <li key={design.id} className="flex flex-col gap-3 rounded-[22px] border border-white/12 bg-white/6 p-3">
                <Image
                  src={content(`templates/${design.preview}`)}
                  alt={fill(dict.studio.previewAlt, { name: design.name })}
                  width={design.previewWidth}
                  height={design.previewHeight}
                  sizes="(max-width: 640px) 100vw, 280px"
                  className="aspect-[6/5] w-full rounded-[14px] object-cover object-top-left"
                />
                <span className="flex justify-between gap-2 px-1 pb-1 text-sm">
                  <span className="font-bold">{design.name}</span>
                  <span className="text-[#aebbdd]">{dict.topics[design.topic as keyof typeof dict.topics]}</span>
                </span>
              </li>
            ))}
          </ul>
        </div>
      </section>

      {/* Languages */}
      <section className="mx-auto flex max-w-[1200px] flex-col gap-9 px-4 pt-28 pb-10 sm:px-6">
        <div className="flex flex-col items-center gap-3 text-center">
          <span lang="en" className="text-sm font-bold tracking-wide text-link uppercase">
            {dict.languages.eyebrow}
          </span>
          <h2 className="text-[clamp(30px,3.6vw,44px)] leading-[1.6] font-bold">{dict.languages.title}</h2>
          <p className="max-w-[620px] text-[17px] text-muted-foreground">{dict.languages.body}</p>
        </div>
        <ul className="grid grid-cols-[repeat(auto-fit,minmax(min(100%,340px),1fr))] gap-4">
          {languages.samples.map((sample) => {
            const zawgyi = sample.language === "zawgyi";
            return (
              <li key={sample.language} className="flex flex-col gap-1.5 rounded-[20px] border bg-card px-6 py-5">
                <span className="text-[13px] font-bold text-muted-foreground">
                  {dict.languages.names[sample.language as keyof typeof dict.languages.names]}
                </span>
                <span
                  lang={sample.language === "en" ? "en" : "my"}
                  className="text-xl leading-[2] font-semibold"
                  style={zawgyi ? { fontFamily: "Zawgyi-One, var(--font-myanmar)" } : undefined}
                >
                  {sample.text}
                </span>
                {zawgyi && <span className="text-xs text-muted-foreground">{dict.languages.zawgyiNote}</span>}
              </li>
            );
          })}
        </ul>
      </section>

      {/* FAQ */}
      <section className="mx-auto flex max-w-[820px] flex-col gap-7 px-4 pt-24 pb-28 sm:px-6">
        <h2 className="text-center text-[clamp(30px,3.6vw,40px)] leading-[1.6] font-bold">{dict.faq.title}</h2>
        <Faq items={dict.faq.items} />
      </section>

      {/* Call to action */}
      <section className="relative overflow-hidden bg-[linear-gradient(180deg,#14203d_0%,#0d1328_100%)] text-center text-[#f7f9fe]">
        <Stars count={12} seed={19} />
        <div className="relative mx-auto flex max-w-[760px] flex-col items-center gap-5 px-4 py-24 sm:px-6">
          <Moon className="size-[110px]" />
          <h2 className="mt-2 text-[clamp(30px,3.6vw,44px)] leading-[1.6] font-bold">{dict.cta.title}</h2>
          <p className="text-[17px] text-night-100">{dict.cta.body}</p>
          <StoreButtons dict={dict} className="justify-center" />
          {webAppUrl && (
            <a
              href={webAppUrl}
              className="rounded-2xl bg-gold px-6 py-3.5 font-bold text-night-800 no-underline hover:bg-[#f7d27e]"
            >
              {dict.store.openWeb}
            </a>
          )}
        </div>
      </section>
    </>
  );
}
