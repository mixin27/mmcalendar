import Image from "next/image";

import { content } from "@/lib/site";
import { cn } from "@/lib/utils";

/** An app screenshot (600 × 1303) in a plain phone frame. */
export function Phone({
  src,
  alt,
  className,
  priority = false,
}: {
  src: string;
  alt: string;
  className?: string;
  priority?: boolean;
}) {
  return (
    <div
      className={cn(
        "rounded-[46px] bg-[#0a0a0f] p-2.5 shadow-[0_30px_80px_rgb(5_10_30/0.45)]",
        className,
      )}
    >
      <Image
        src={content(`app/${src}`)}
        alt={alt}
        width={600}
        height={1303}
        priority={priority}
        sizes="(max-width: 640px) 70vw, 300px"
        className="block h-auto w-full rounded-[36px]"
      />
    </div>
  );
}
