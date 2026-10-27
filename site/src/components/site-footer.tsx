import Image from "next/image";
import Link from "next/link";

import type { Dictionary, Locale } from "@/app/[lang]/dictionaries";
import { content, links } from "@/lib/site";

export function SiteFooter({ dict, locale }: { dict: Dictionary; locale: Locale }) {
  return (
    <footer className="bg-night-900 text-[#aebbdd]">
      <div className="mx-auto flex max-w-[1200px] flex-wrap items-start justify-between gap-x-12 gap-y-7 px-4 py-12 sm:px-6">
        <div className="flex max-w-90 flex-col gap-3">
          <span className="flex items-center gap-3 font-bold text-[#f7f9fe]">
            <Image src={content("brand/icon.png")} alt="" width={32} height={32} className="rounded-lg" />
            {dict.appName}
          </span>
          <span className="text-sm" lang="en">
            {dict.footer.made}
          </span>
        </div>
        <nav aria-label={dict.footer.label} className="flex flex-wrap gap-x-7 gap-y-3 text-sm">
          <Link href={`/${locale}/privacy`} className="text-night-100 hover:text-white">
            {dict.footer.privacy}
          </Link>
          <Link href={`/${locale}/support`} className="text-night-100 hover:text-white">
            {dict.footer.support}
          </Link>
          <Link href={`/${locale}/whats-new`} className="text-night-100 hover:text-white">
            {dict.footer.whatsNew}
          </Link>
          <a href={links.github} className="text-night-100 hover:text-white">
            {dict.footer.github}
          </a>
          <a href={`mailto:${links.email}`} className="text-night-100 hover:text-white">
            {links.email}
          </a>
        </nav>
      </div>
      <div className="border-t border-white/10 px-4 py-4 text-center text-[13px]">
        © 2026 {links.author} · {dict.footer.license}
      </div>
    </footer>
  );
}
