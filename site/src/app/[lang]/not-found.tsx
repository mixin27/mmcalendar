import Link from "next/link";

import { Moon, Stars } from "@/components/night-sky";
import { getDictionary, getLocale } from "./dictionaries";

export default async function NotFound() {
  const [dict, locale] = await Promise.all([getDictionary(), getLocale()]);
  return (
    <section className="night relative flex min-h-[70dvh] flex-col items-center justify-center gap-6 overflow-hidden px-4 text-center">
      <Stars count={14} seed={23} />
      <Moon className="size-24" />
      <h1 className="relative text-3xl font-bold">{dict.notFound.title}</h1>
      <Link href={`/${locale}`} className="relative rounded-full bg-gold px-5 py-3 font-bold text-night-800 no-underline">
        {dict.notFound.home}
      </Link>
    </section>
  );
}
