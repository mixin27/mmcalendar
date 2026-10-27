import { lang } from "next/root-params";
import { notFound } from "next/navigation";

const dictionaries = {
  my: () => import("./dictionaries/my.json").then((module) => module.default),
  en: () => import("./dictionaries/en.json").then((module) => module.default),
};

export type Locale = keyof typeof dictionaries;
export type Dictionary = Awaited<ReturnType<(typeof dictionaries)["en"]>>;

/** Myanmar first: it's the default for visitors whose browser doesn't ask for English. */
export const locales = ["my", "en"] as const satisfies readonly Locale[];
export const defaultLocale: Locale = "my";

export const hasLocale = (locale: string): locale is Locale => locale in dictionaries;

/** The current page's locale, from the `[lang]` root segment. */
export async function getLocale(): Promise<Locale> {
  const locale = await lang();
  if (!hasLocale(locale)) notFound();
  return locale;
}

export async function getDictionary(): Promise<Dictionary> {
  return dictionaries[await getLocale()]();
}
