import type { Metadata, Viewport } from "next";
import { Inter, Noto_Sans_Myanmar } from "next/font/google";

import "../globals.css";
import { SiteFooter } from "@/components/site-footer";
import { links, siteUrl } from "@/lib/site";
import { getDictionary, getLocale, locales } from "./dictionaries";

const inter = Inter({ subsets: ["latin"], variable: "--font-inter", display: "swap" });
const myanmar = Noto_Sans_Myanmar({
  subsets: ["myanmar", "latin"],
  variable: "--font-myanmar",
  display: "swap",
});

export async function generateStaticParams() {
  return locales.map((lang) => ({ lang }));
}

export async function generateMetadata(): Promise<Metadata> {
  const [dict, locale] = await Promise.all([getDictionary(), getLocale()]);
  return {
    metadataBase: new URL(siteUrl),
    title: { default: dict.meta.title, template: `%s · ${dict.meta.siteName}` },
    description: dict.meta.description,
    applicationName: dict.meta.siteName,
    alternates: {
      canonical: `/${locale}`,
      languages: { my: "/my", en: "/en", "x-default": "/my" },
    },
    openGraph: {
      type: "website",
      siteName: dict.meta.siteName,
      title: dict.meta.title,
      description: dict.meta.description,
      locale: locale === "my" ? "my_MM" : "en_US",
      url: `/${locale}`,
    },
    twitter: { card: "summary_large_image", title: dict.meta.title, description: dict.meta.description },
    // iOS Safari shows an "Open in the App Store" banner.
    itunes: { appId: links.appStoreId },
  };
}

export const viewport: Viewport = {
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#14203d" },
    { media: "(prefers-color-scheme: dark)", color: "#0d1328" },
  ],
};

export default async function RootLayout({ children }: LayoutProps<"/[lang]">) {
  const [dict, locale] = await Promise.all([getDictionary(), getLocale()]);
  return (
    <html lang={locale} className={`${inter.variable} ${myanmar.variable}`}>
      <body className="flex min-h-dvh flex-col">
        <a
          href="#content"
          className="sr-only focus:not-sr-only focus:absolute focus:top-3 focus:left-3 focus:z-50 focus:rounded-lg focus:bg-white focus:px-4 focus:py-2 focus:text-night-800"
        >
          {dict.nav.skip}
        </a>
        <div className="flex-1">{children}</div>
        <SiteFooter dict={dict} locale={locale} />
      </body>
    </html>
  );
}
