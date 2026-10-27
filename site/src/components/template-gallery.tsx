"use client";

import Image from "next/image";
import { useState } from "react";

import { content } from "@/lib/site";
import { cn } from "@/lib/utils";

type Design = {
  id: string;
  name: string;
  topic: string;
  size: string;
  blurb: string;
  preview: string;
  previewWidth: number;
  previewHeight: number;
  project: string;
  template: string;
};

/** The template cards with topic chips that filter them. */
export function TemplateGallery({
  designs,
  topics,
  labels,
}: {
  designs: Design[];
  topics: Record<string, string>;
  labels: { filter: string; project: string; template: string };
}) {
  const [topic, setTopic] = useState("all");
  const shown = topic === "all" ? designs : designs.filter((design) => design.topic === topic);
  return (
    <div className="flex flex-col gap-7">
      <div role="group" aria-label={labels.filter} className="flex flex-wrap gap-2.5">
        {Object.entries(topics).map(([key, label]) => {
          const active = key === topic;
          return (
            <button
              key={key}
              type="button"
              aria-pressed={active}
              onClick={() => setTopic(key)}
              className={cn(
                "min-h-11 rounded-full border px-4.5 py-2 text-[15px] font-semibold transition-colors",
                active
                  ? "border-night-800 bg-night-800 text-[#f7f9fe] dark:border-gold dark:bg-gold dark:text-night-800"
                  : "border-input bg-card hover:border-night-600",
              )}
            >
              {label}
            </button>
          );
        })}
      </div>

      <ul className="grid grid-cols-[repeat(auto-fit,minmax(min(100%,340px),1fr))] gap-6">
        {shown.map((design) => (
          <li key={design.id} className="flex flex-col overflow-hidden rounded-3xl border bg-card">
            <Image
              src={content(`templates/${design.preview}`)}
              alt={`${design.name}: all 13 pages`}
              width={design.previewWidth}
              height={design.previewHeight}
              sizes="(max-width: 760px) 100vw, 380px"
              className="aspect-[6/5] w-full bg-panel object-cover object-top-left"
            />
            <div className="flex flex-1 flex-col gap-2.5 px-5.5 pt-5 pb-5.5">
              <div className="flex items-baseline justify-between gap-3">
                <h2 className="text-xl font-bold">{design.name}</h2>
                <span className="text-[13px] text-muted-foreground">
                  {topics[design.topic]} · {design.size}
                </span>
              </div>
              <p className="flex-1 text-sm leading-[1.85] text-muted-foreground">{design.blurb}</p>
              <div className="mt-1.5 flex flex-wrap gap-2">
                <a
                  href={content(`templates/${design.project}`)}
                  download
                  className="flex-[1_1_140px] rounded-xl bg-primary px-3.5 py-2.5 text-center text-sm font-semibold text-primary-foreground no-underline hover:bg-primary/85"
                >
                  {labels.project}
                </a>
                <a
                  href={content(`templates/${design.template}`)}
                  download
                  className="flex-[1_1_140px] rounded-xl bg-secondary px-3.5 py-2.5 text-center text-sm font-semibold text-secondary-foreground no-underline hover:bg-secondary/80"
                >
                  {labels.template}
                </a>
              </div>
            </div>
          </li>
        ))}
      </ul>
    </div>
  );
}
