#!/usr/bin/env python3
"""Generate clean Myanmar Calendar brand assets without external deps.

Outputs:
- apps/myanmar_calendar/assets/branding/app_icon_1024.png
- apps/myanmar_calendar/assets/branding/feature_graphic_1024x500.png
- apps/myanmar_calendar/assets/images/logo.png
- assets/logo.png
- apps/myanmar_calendar/android/app/src/main/ic_launcher-playstore.png
- screenshots/myanmar-calendar-featured-graphic.png
"""

from __future__ import annotations

import math
import os
import shutil
import subprocess
import tempfile
from dataclasses import dataclass


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))


def _clamp(value: float, lo: float = 0.0, hi: float = 1.0) -> float:
    return lo if value < lo else hi if value > hi else value


def _lerp(a: float, b: float, t: float) -> float:
    return a + (b - a) * t


def _lerp_color(c1: tuple[int, int, int], c2: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return (
        int(_lerp(c1[0], c2[0], t)),
        int(_lerp(c1[1], c2[1], t)),
        int(_lerp(c1[2], c2[2], t)),
    )


@dataclass
class Raster:
    width: int
    height: int

    def __post_init__(self) -> None:
        self.data = bytearray(self.width * self.height * 3)

    def _idx(self, x: int, y: int) -> int:
        return (y * self.width + x) * 3

    def set_rgb(self, x: int, y: int, color: tuple[int, int, int]) -> None:
        if x < 0 or y < 0 or x >= self.width or y >= self.height:
            return
        i = self._idx(x, y)
        self.data[i] = color[0]
        self.data[i + 1] = color[1]
        self.data[i + 2] = color[2]

    def blend_rgb(self, x: int, y: int, color: tuple[int, int, int], alpha: float) -> None:
        if alpha <= 0.0:
            return
        if x < 0 or y < 0 or x >= self.width or y >= self.height:
            return
        a = _clamp(alpha)
        i = self._idx(x, y)
        self.data[i] = int(self.data[i] * (1.0 - a) + color[0] * a)
        self.data[i + 1] = int(self.data[i + 1] * (1.0 - a) + color[1] * a)
        self.data[i + 2] = int(self.data[i + 2] * (1.0 - a) + color[2] * a)

    def write_ppm(self, path: str) -> None:
        with open(path, "wb") as f:
            f.write(f"P6\n{self.width} {self.height}\n255\n".encode("ascii"))
            f.write(self.data)


def draw_linear_gradient(
    img: Raster,
    c_tl: tuple[int, int, int],
    c_br: tuple[int, int, int],
) -> None:
    denom = float((img.width - 1) + (img.height - 1))
    for y in range(img.height):
        for x in range(img.width):
            t = ((x + y) / denom) if denom > 0 else 0.0
            img.set_rgb(x, y, _lerp_color(c_tl, c_br, t))


def draw_radial_light(
    img: Raster,
    cx: float,
    cy: float,
    radius: float,
    color: tuple[int, int, int],
    alpha: float,
) -> None:
    x0 = max(0, int(cx - radius - 2))
    x1 = min(img.width, int(cx + radius + 2))
    y0 = max(0, int(cy - radius - 2))
    y1 = min(img.height, int(cy + radius + 2))
    for y in range(y0, y1):
        dy = (y + 0.5) - cy
        for x in range(x0, x1):
            dx = (x + 0.5) - cx
            d = math.sqrt(dx * dx + dy * dy)
            t = _clamp(1.0 - d / radius)
            if t <= 0:
                continue
            a = alpha * (t * t)
            img.blend_rgb(x, y, color, a)


def draw_circle(
    img: Raster,
    cx: float,
    cy: float,
    radius: float,
    color: tuple[int, int, int],
    alpha: float = 1.0,
) -> None:
    x0 = max(0, int(cx - radius - 2))
    x1 = min(img.width, int(cx + radius + 2))
    y0 = max(0, int(cy - radius - 2))
    y1 = min(img.height, int(cy + radius + 2))
    for y in range(y0, y1):
        dy = (y + 0.5) - cy
        for x in range(x0, x1):
            dx = (x + 0.5) - cx
            dist = math.sqrt(dx * dx + dy * dy)
            coverage = _clamp(radius + 0.6 - dist)
            if coverage > 0:
                img.blend_rgb(x, y, color, alpha * coverage)


def _sdf_rounded_rect(px: float, py: float, cx: float, cy: float, hw: float, hh: float, r: float) -> float:
    qx = abs(px - cx) - (hw - r)
    qy = abs(py - cy) - (hh - r)
    ax = max(qx, 0.0)
    ay = max(qy, 0.0)
    outside = math.sqrt(ax * ax + ay * ay)
    inside = min(max(qx, qy), 0.0)
    return outside + inside - r


def draw_rounded_rect(
    img: Raster,
    x: float,
    y: float,
    w: float,
    h: float,
    radius: float,
    color: tuple[int, int, int],
    alpha: float = 1.0,
) -> None:
    cx = x + w / 2.0
    cy = y + h / 2.0
    hw = w / 2.0
    hh = h / 2.0
    x0 = max(0, int(x - 2))
    x1 = min(img.width, int(x + w + 2))
    y0 = max(0, int(y - 2))
    y1 = min(img.height, int(y + h + 2))
    r = min(radius, hw - 1.0, hh - 1.0)
    for py in range(y0, y1):
        fy = py + 0.5
        for px in range(x0, x1):
            fx = px + 0.5
            d = _sdf_rounded_rect(fx, fy, cx, cy, hw, hh, r)
            coverage = _clamp(0.75 - d)
            if coverage > 0:
                img.blend_rgb(px, py, color, alpha * coverage)


def draw_hline(img: Raster, x0: float, x1: float, y: float, thickness: float, color: tuple[int, int, int], alpha: float = 1.0) -> None:
    draw_rounded_rect(img, x0, y - thickness / 2.0, x1 - x0, thickness, thickness / 2.0, color, alpha)


def draw_vline(img: Raster, x: float, y0: float, y1: float, thickness: float, color: tuple[int, int, int], alpha: float = 1.0) -> None:
    draw_rounded_rect(img, x - thickness / 2.0, y0, thickness, y1 - y0, thickness / 2.0, color, alpha)


def draw_calendar_mark(img: Raster, cx: float, cy: float, size: float) -> None:
    card_w = size * 0.70
    card_h = size * 0.78
    x = cx - card_w / 2.0
    y = cy - card_h / 2.0
    radius = size * 0.12

    # Shadow
    draw_rounded_rect(
        img,
        x + size * 0.016,
        y + size * 0.02,
        card_w,
        card_h,
        radius,
        (10, 25, 40),
        0.30,
    )

    # Card
    draw_rounded_rect(img, x, y, card_w, card_h, radius, (246, 250, 255), 0.98)

    # Top strip
    top_h = card_h * 0.24
    draw_rounded_rect(img, x, y, card_w, top_h, radius, (18, 176, 183), 1.0)
    draw_rounded_rect(img, x, y + top_h * 0.55, card_w, top_h * 0.45, radius * 0.6, (13, 148, 171), 0.55)

    # Binder rings
    ring_y = y + top_h * 0.52
    ring_dx = card_w * 0.24
    for i in (-1, 1):
        draw_circle(img, cx + ring_dx * i, ring_y, size * 0.020, (235, 250, 255), 1.0)
        draw_circle(img, cx + ring_dx * i, ring_y, size * 0.010, (12, 74, 110), 1.0)

    body_y = y + top_h + size * 0.018
    body_h = card_h - top_h - size * 0.05
    line_c = (206, 216, 230)

    # Grid
    for k in range(1, 3):
        gx = x + (card_w / 3.0) * k
        draw_vline(img, gx, body_y, body_y + body_h, max(1.0, size * 0.0065), line_c, 0.9)
    for k in range(1, 3):
        gy = body_y + (body_h / 3.0) * k
        draw_hline(img, x + size * 0.02, x + card_w - size * 0.02, gy, max(1.0, size * 0.0065), line_c, 0.9)

    # Moon crescent
    moon_cx = cx
    moon_cy = body_y + body_h * 0.56
    moon_r = size * 0.11
    draw_circle(img, moon_cx, moon_cy, moon_r, (22, 163, 184), 1.0)
    draw_circle(img, moon_cx + moon_r * 0.45, moon_cy - moon_r * 0.08, moon_r * 0.95, (246, 250, 255), 1.0)

    # Accent star
    star_c = (245, 196, 86)
    draw_circle(img, moon_cx + moon_r * 1.15, moon_cy - moon_r * 0.95, size * 0.022, star_c, 1.0)
    draw_hline(
        img,
        moon_cx + moon_r * 1.15 - size * 0.028,
        moon_cx + moon_r * 1.15 + size * 0.028,
        moon_cy - moon_r * 0.95,
        size * 0.007,
        star_c,
        0.8,
    )
    draw_vline(
        img,
        moon_cx + moon_r * 1.15,
        moon_cy - moon_r * 0.95 - size * 0.028,
        moon_cy - moon_r * 0.95 + size * 0.028,
        size * 0.007,
        star_c,
        0.8,
    )


def render_icon(size: int) -> Raster:
    img = Raster(size, size)
    draw_linear_gradient(img, (11, 27, 47), (15, 118, 110))
    draw_radial_light(img, size * 0.26, size * 0.2, size * 0.62, (56, 189, 248), 0.24)
    draw_radial_light(img, size * 0.78, size * 0.82, size * 0.7, (16, 185, 129), 0.16)

    # Soft ring for depth
    draw_circle(img, size * 0.5, size * 0.5, size * 0.39, (236, 253, 245), 0.10)
    draw_circle(img, size * 0.5, size * 0.5, size * 0.36, (9, 19, 33), 0.14)

    draw_calendar_mark(img, size * 0.5, size * 0.5, size * 0.88)
    return img


def render_feature_graphic(width: int, height: int) -> Raster:
    img = Raster(width, height)
    draw_linear_gradient(img, (10, 18, 34), (13, 92, 112))
    draw_radial_light(img, width * 0.2, height * 0.15, width * 0.5, (45, 212, 191), 0.20)
    draw_radial_light(img, width * 0.95, height * 0.8, width * 0.55, (14, 165, 233), 0.18)

    # Decorative blobs
    draw_circle(img, width * 0.82, height * 0.22, width * 0.16, (148, 163, 184), 0.09)
    draw_circle(img, width * 0.73, height * 0.73, width * 0.11, (251, 191, 36), 0.09)
    draw_circle(img, width * 0.93, height * 0.58, width * 0.10, (56, 189, 248), 0.10)

    # Right-side clean panel
    draw_rounded_rect(
        img,
        width * 0.55,
        height * 0.08,
        width * 0.40,
        height * 0.84,
        32,
        (255, 255, 255),
        0.09,
    )

    # Left hero mark
    draw_calendar_mark(img, width * 0.30, height * 0.50, min(width, height) * 0.88)

    # Minimal chips on right panel
    chip_color = (245, 250, 255)
    chip_bg = (20, 184, 166)
    chip_w = width * 0.26
    chip_h = height * 0.12
    start_x = width * 0.61
    ys = [height * 0.24, height * 0.42, height * 0.60]
    for y in ys:
        draw_rounded_rect(img, start_x, y, chip_w, chip_h, chip_h * 0.45, chip_bg, 0.28)
        draw_circle(img, start_x + chip_h * 0.48, y + chip_h * 0.5, chip_h * 0.22, chip_color, 0.85)
        draw_rounded_rect(
            img,
            start_x + chip_h * 0.9,
            y + chip_h * 0.36,
            chip_w * 0.66,
            chip_h * 0.24,
            chip_h * 0.12,
            chip_color,
            0.72,
        )
    return img


def convert_ppm_to_png(ppm_path: str, png_path: str) -> None:
    os.makedirs(os.path.dirname(png_path), exist_ok=True)
    subprocess.run(
        ["sips", "-s", "format", "png", ppm_path, "--out", png_path],
        check=True,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
    )


def write_png(raster: Raster, output_path: str) -> None:
    with tempfile.NamedTemporaryFile(suffix=".ppm", delete=False) as tmp:
        ppm_path = tmp.name
    try:
        raster.write_ppm(ppm_path)
        convert_ppm_to_png(ppm_path, output_path)
    finally:
        if os.path.exists(ppm_path):
            os.remove(ppm_path)


def main() -> None:
    icon_1024 = render_icon(1024)
    icon_512 = render_icon(512)
    feature = render_feature_graphic(1024, 500)

    icon_master_path = os.path.join(
        ROOT, "apps", "myanmar_calendar", "assets", "branding", "app_icon_1024.png"
    )
    feature_path = os.path.join(
        ROOT,
        "apps",
        "myanmar_calendar",
        "assets",
        "branding",
        "feature_graphic_1024x500.png",
    )
    logo_app_path = os.path.join(
        ROOT, "apps", "myanmar_calendar", "assets", "images", "logo.png"
    )
    logo_root_path = os.path.join(ROOT, "assets", "logo.png")
    play_store_icon_path = os.path.join(
        ROOT,
        "apps",
        "myanmar_calendar",
        "android",
        "app",
        "src",
        "main",
        "ic_launcher-playstore.png",
    )
    screenshot_feature_path = os.path.join(
        ROOT, "screenshots", "myanmar-calendar-featured-graphic.png"
    )

    write_png(icon_1024, icon_master_path)
    write_png(icon_512, logo_app_path)
    write_png(icon_512, logo_root_path)
    write_png(icon_512, play_store_icon_path)
    write_png(feature, feature_path)
    write_png(feature, screenshot_feature_path)

    print("Generated brand assets:")
    print(f"- {icon_master_path}")
    print(f"- {feature_path}")
    print(f"- {logo_app_path}")
    print(f"- {logo_root_path}")
    print(f"- {play_store_icon_path}")
    print(f"- {screenshot_feature_path}")


if __name__ == "__main__":
    main()
