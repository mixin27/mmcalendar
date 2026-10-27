import { readFile } from "node:fs/promises";
import { join } from "node:path";

import { ImageResponse } from "next/og";

export const alt = "Myanmar Calendar — the Myanmar calendar in your pocket";
export const size = { width: 1200, height: 630 };
export const contentType = "image/png";

export function generateStaticParams() {
  return [{ lang: "my" }, { lang: "en" }];
}

/**
 * The share image for every page. English only: the image renderer can't
 * shape Myanmar script, which would come out with misplaced marks.
 */
/** Read at build time, so the image is prerendered rather than drawn per request. */
async function iconDataUrl() {
  "use cache";
  const icon = await readFile(join(process.cwd(), "public/content/brand/icon.png"));
  return `data:image/png;base64,${icon.toString("base64")}`;
}

export default async function OpenGraphImage() {
  const icon = await iconDataUrl();
  const stars = [
    [80, 90], [210, 470], [340, 150], [470, 540], [560, 70], [690, 380],
    [820, 560], [930, 120], [1060, 470], [1130, 250], [150, 300], [620, 250],
  ];
  return new ImageResponse(
    (
      <div
        style={{
          width: "100%",
          height: "100%",
          display: "flex",
          alignItems: "center",
          padding: "0 96px",
          background: "linear-gradient(165deg, #0D1328 0%, #14203D 50%, #2B5598 100%)",
          color: "#F7F9FE",
          position: "relative",
        }}
      >
        {stars.map(([x, y], index) => (
          <div
            key={index}
            style={{
              position: "absolute",
              left: x,
              top: y,
              width: index % 3 ? 3 : 4,
              height: index % 3 ? 3 : 4,
              borderRadius: 9999,
              background: "#F4C562",
              opacity: 0.8,
            }}
          />
        ))}
        <div
          style={{
            position: "absolute",
            right: 110,
            top: 90,
            width: 220,
            height: 220,
            borderRadius: 9999,
            background: "radial-gradient(circle at 36% 34%, #FFF7DD 0%, #F4C562 58%, #D9A33A 100%)",
            boxShadow: "0 0 120px 40px rgba(244,197,98,0.35)",
          }}
        />
        <div style={{ display: "flex", flexDirection: "column", gap: 24, maxWidth: 760 }}>
          <img
            src={icon}
            width={120}
            height={120}
            style={{ borderRadius: 28 }}
            alt=""
          />
          <div style={{ fontSize: 84, fontWeight: 700, lineHeight: 1.05 }}>Myanmar Calendar</div>
          <div style={{ fontSize: 36, color: "#C9D4F0" }}>The Myanmar calendar in your pocket</div>
          <div style={{ fontSize: 26, color: "#F4C562" }}>Android · iOS · Web — free</div>
        </div>
      </div>
    ),
    size,
  );
}
