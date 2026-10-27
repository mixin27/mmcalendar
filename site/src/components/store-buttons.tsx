import type { Dictionary } from "@/app/[lang]/dictionaries";
import { links } from "@/lib/site";
import { cn } from "@/lib/utils";

function StoreButton({
  href,
  top,
  name,
  icon,
}: {
  href: string;
  top: string;
  name: string;
  icon: React.ReactNode;
}) {
  return (
    <a
      href={href}
      className="flex min-h-11 items-center gap-3 rounded-2xl border border-white/25 bg-[#0a0a0f] py-2.5 pr-5 pl-4 text-white no-underline transition-colors hover:border-white/50"
    >
      {icon}
      <span className="flex flex-col leading-tight">
        <span className="text-[11px] opacity-80">{top}</span>
        <span className="text-lg font-semibold">{name}</span>
      </span>
    </a>
  );
}

/** The two store links, as plain buttons (not the stores' trademarked badges). */
export function StoreButtons({ dict, className }: { dict: Dictionary; className?: string }) {
  return (
    <div className={cn("flex flex-wrap gap-3", className)}>
      <StoreButton
        href={links.appStore}
        top={dict.store.appStoreTop}
        name={dict.store.appStore}
        icon={
          <svg aria-hidden="true" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinecap="round" strokeLinejoin="round">
            <rect x="6" y="2.5" width="12" height="19" rx="3" />
            <path d="M10.5 18.5h3" />
          </svg>
        }
      />
      <StoreButton
        href={links.googlePlay}
        top={dict.store.playTop}
        name={dict.store.play}
        icon={
          <svg aria-hidden="true" width="26" height="26" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" strokeLinejoin="round">
            <path d="M5 3.5v17l14-8.5z" />
          </svg>
        }
      />
    </div>
  );
}
