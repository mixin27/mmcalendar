"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";

import { cn } from "@/lib/utils";

const options = [
  { locale: "my", label: "မြန်မာ" },
  { locale: "en", label: "EN" },
] as const;

/** Swaps the locale at the start of the current path. */
export function LanguageSwitch({ current, label }: { current: string; label: string }) {
  const pathname = usePathname();
  const rest = pathname.replace(/^\/(my|en)(?=\/|$)/, "");
  return (
    <div role="group" aria-label={label} className="flex rounded-full bg-white/10 p-[3px] text-[13px]">
      {options.map((option) => {
        const active = option.locale === current;
        return (
          <Link
            key={option.locale}
            href={`/${option.locale}${rest}`}
            hrefLang={option.locale}
            lang={option.locale}
            aria-current={active ? "true" : undefined}
            className={cn(
              "rounded-full px-3 py-1.5 font-semibold no-underline",
              active ? "bg-[#f7f9fe] text-night-800" : "text-night-100 hover:text-white",
            )}
          >
            {option.label}
          </Link>
        );
      })}
    </div>
  );
}
