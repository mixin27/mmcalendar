import type { Dictionary, Locale } from "@/app/[lang]/dictionaries";
import { Stars } from "@/components/night-sky";
import { SiteHeader } from "@/components/site-header";

/** A page's opening night band: header, then the page's own heading. */
export function NightHero({
  dict,
  locale,
  children,
}: {
  dict: Dictionary;
  locale: Locale;
  children: React.ReactNode;
}) {
  return (
    <section className="night relative overflow-hidden">
      <Stars count={16} seed={11} />
      <SiteHeader dict={dict} locale={locale} />
      <div id="content" className="relative mx-auto flex max-w-[1200px] flex-col gap-3.5 px-4 pt-10 pb-16 sm:px-6">
        {children}
      </div>
    </section>
  );
}

export function Eyebrow({ children, className = "" }: { children: React.ReactNode; className?: string }) {
  return <span className={`text-sm font-bold tracking-wide ${className}`}>{children}</span>;
}
