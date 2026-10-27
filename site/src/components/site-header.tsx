import Image from "next/image";
import Link from "next/link";

import type { Dictionary, Locale } from "@/app/[lang]/dictionaries";
import { LanguageSwitch } from "@/components/language-switch";
import { content } from "@/lib/site";

/** The night-band header; sits over each page's night hero. */
export function SiteHeader({ dict, locale }: { dict: Dictionary; locale: Locale }) {
  const home = `/${locale}`;
  const nav = [
    { href: `${home}#features`, label: dict.nav.features },
    { href: `${home}#studio`, label: dict.nav.studio },
    { href: `${home}/templates`, label: dict.nav.templates },
    { href: `${home}/whats-new`, label: dict.nav.whatsNew },
  ];
  return (
    <header className="relative mx-auto flex max-w-[1200px] flex-wrap items-center gap-x-7 gap-y-4 px-4 py-5 sm:px-6">
      <Link href={home} className="mr-auto flex items-center gap-3 text-[#f7f9fe] no-underline">
        <Image src={content("brand/icon.png")} alt="" width={40} height={40} className="rounded-[10px]" />
        <span className="text-lg font-bold">{dict.appName}</span>
      </Link>
      <nav aria-label={dict.nav.label} className="flex flex-wrap gap-x-6 gap-y-2 text-[15px]">
        {nav.map((item) => (
          <Link key={item.href} href={item.href} className="text-night-100 no-underline hover:text-white">
            {item.label}
          </Link>
        ))}
      </nav>
      <div className="flex items-center gap-3">
        <LanguageSwitch current={locale} label={dict.nav.language} />
        <Link
          href={`${home}#download`}
          className="rounded-full bg-gold px-4 py-2.5 text-sm font-bold text-night-800 no-underline hover:bg-[#f7d27e]"
        >
          {dict.nav.download}
        </Link>
      </div>
    </header>
  );
}
