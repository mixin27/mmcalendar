#!/usr/bin/env python3
"""Generate clean Myanmar Calendar brand assets without external deps.

Outputs:
- apps/myanmar_calendar/assets/branding/app_icon_1024.png
- apps/myanmar_calendar/assets/branding/app_icon_moon_1024.png
- apps/myanmar_calendar/assets/branding/app_icon_forest_1024.png
- apps/myanmar_calendar/assets/branding/app_icon_minimal_flat_1024.png
- apps/myanmar_calendar/assets/branding/app_icon_premium_dark_1024.png
- apps/myanmar_calendar/assets/branding/app_icon_traditional_myanmar_1024.png
- apps/myanmar_calendar/assets/branding/feature_graphic_1024x500.png
- apps/myanmar_calendar/assets/images/logo.png
- assets/logo.png
- apps/myanmar_calendar/android/app/src/main/ic_launcher-playstore.png
- screenshots/myanmar-calendar-featured-graphic.png
"""

from __future__ import annotations

import math
import json
import os
import shutil
import subprocess
import tempfile
from dataclasses import dataclass


ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))

ANDROID_MIPMAP_SIZES = {
    "mdpi": 48,
    "hdpi": 72,
    "xhdpi": 96,
    "xxhdpi": 144,
    "xxxhdpi": 192,
}

ICON_RESOURCE_NAMES = {
    "default": "ic_launcher",
    "moon": "ic_launcher_moon",
    "forest": "ic_launcher_forest",
    "minimal_flat": "ic_launcher_minimal_flat",
    "premium_dark": "ic_launcher_premium_dark",
    "traditional_myanmar": "ic_launcher_traditional_myanmar",
}

ICON_MASTER_FILENAMES = {
    "default": "app_icon_1024.png",
    "moon": "app_icon_moon_1024.png",
    "forest": "app_icon_forest_1024.png",
    "minimal_flat": "app_icon_minimal_flat_1024.png",
    "premium_dark": "app_icon_premium_dark_1024.png",
    "traditional_myanmar": "app_icon_traditional_myanmar_1024.png",
}

IOS_ALT_ICONSET_NAMES = {
    "moon": "AppIconMoon",
    "forest": "AppIconForest",
    "minimal_flat": "AppIconMinimalFlat",
    "premium_dark": "AppIconPremiumDark",
    "traditional_myanmar": "AppIconTraditionalMyanmar",
}

_IOS_ICONSET_ALLOWED_KEYS = (
    "idiom",
    "size",
    "scale",
    "role",
    "subtype",
    "platform",
    "filename",
)


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


@dataclass(frozen=True)
class IconPalette:
    gradient_tl: tuple[int, int, int]
    gradient_br: tuple[int, int, int]
    light_a: tuple[int, int, int]
    light_a_alpha: float
    light_b: tuple[int, int, int]
    light_b_alpha: float
    ring_outer: tuple[int, int, int]
    ring_inner: tuple[int, int, int]
    top_strip_primary: tuple[int, int, int]
    top_strip_secondary: tuple[int, int, int]
    moon_color: tuple[int, int, int]
    star_color: tuple[int, int, int]


ICON_PALETTES = {
    "default": IconPalette(
        gradient_tl=(16, 30, 66),
        gradient_br=(42, 89, 155),
        light_a=(152, 190, 255),
        light_a_alpha=0.16,
        light_b=(79, 132, 228),
        light_b_alpha=0.22,
        ring_outer=(242, 245, 255),
        ring_inner=(142, 166, 212),
        top_strip_primary=(39, 78, 146),
        top_strip_secondary=(19, 42, 95),
        moon_color=(123, 181, 255),
        star_color=(255, 213, 122),
    ),
    "moon": IconPalette(
        gradient_tl=(28, 22, 74),
        gradient_br=(79, 67, 160),
        light_a=(190, 174, 255),
        light_a_alpha=0.16,
        light_b=(120, 103, 220),
        light_b_alpha=0.20,
        ring_outer=(242, 236, 255),
        ring_inner=(168, 152, 222),
        top_strip_primary=(71, 61, 142),
        top_strip_secondary=(36, 30, 90),
        moon_color=(170, 160, 255),
        star_color=(255, 216, 124),
    ),
    "forest": IconPalette(
        gradient_tl=(13, 43, 54),
        gradient_br=(29, 107, 116),
        light_a=(156, 236, 218),
        light_a_alpha=0.14,
        light_b=(74, 177, 164),
        light_b_alpha=0.18,
        ring_outer=(226, 250, 245),
        ring_inner=(120, 187, 177),
        top_strip_primary=(21, 91, 92),
        top_strip_secondary=(9, 52, 60),
        moon_color=(154, 235, 220),
        star_color=(255, 215, 129),
    ),
    "minimal_flat": IconPalette(
        gradient_tl=(41, 54, 78),
        gradient_br=(83, 104, 139),
        light_a=(201, 213, 235),
        light_a_alpha=0.10,
        light_b=(133, 157, 194),
        light_b_alpha=0.14,
        ring_outer=(237, 242, 252),
        ring_inner=(160, 173, 200),
        top_strip_primary=(65, 82, 112),
        top_strip_secondary=(36, 49, 74),
        moon_color=(205, 219, 242),
        star_color=(252, 205, 116),
    ),
    "premium_dark": IconPalette(
        gradient_tl=(8, 13, 26),
        gradient_br=(26, 45, 86),
        light_a=(122, 165, 255),
        light_a_alpha=0.14,
        light_b=(58, 103, 203),
        light_b_alpha=0.18,
        ring_outer=(235, 241, 255),
        ring_inner=(122, 146, 196),
        top_strip_primary=(24, 54, 118),
        top_strip_secondary=(10, 23, 58),
        moon_color=(176, 208, 255),
        star_color=(255, 214, 120),
    ),
    "traditional_myanmar": IconPalette(
        gradient_tl=(39, 23, 56),
        gradient_br=(111, 62, 141),
        light_a=(244, 202, 166),
        light_a_alpha=0.15,
        light_b=(170, 104, 202),
        light_b_alpha=0.18,
        ring_outer=(255, 241, 225),
        ring_inner=(220, 170, 140),
        top_strip_primary=(98, 48, 115),
        top_strip_secondary=(56, 27, 75),
        moon_color=(255, 223, 183),
        star_color=(255, 198, 102),
    ),
}


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


def draw_line(
    img: Raster,
    x0: float,
    y0: float,
    x1: float,
    y1: float,
    thickness: float,
    color: tuple[int, int, int],
    alpha: float = 1.0,
) -> None:
    dx = x1 - x0
    dy = y1 - y0
    steps = max(1, int(max(abs(dx), abs(dy)) * 1.1))
    radius = max(0.8, thickness * 0.5)
    for i in range(steps + 1):
        t = i / steps
        draw_circle(img, x0 + dx * t, y0 + dy * t, radius, color, alpha)


def draw_feature_corner_glyph(
    img: Raster,
    cx: float,
    cy: float,
    size: float,
    *,
    kind: str,
    stroke: tuple[int, int, int],
    accent: tuple[int, int, int],
) -> None:
    t = size * 0.10
    if kind == "grid":
        draw_rounded_rect(img, cx - size * 0.24, cy - size * 0.19, size * 0.48, size * 0.38, size * 0.06, stroke, 0.20)
        draw_hline(img, cx - size * 0.24, cx + size * 0.24, cy - size * 0.05, t, stroke, 0.94)
        draw_vline(img, cx, cy - size * 0.19, cy + size * 0.19, t, stroke, 0.94)
    elif kind == "event":
        draw_hline(img, cx - size * 0.22, cx + size * 0.22, cy - size * 0.09, t, stroke, 0.94)
        draw_hline(img, cx - size * 0.20, cx + size * 0.12, cy + size * 0.05, t, stroke, 0.78)
        draw_circle(img, cx + size * 0.18, cy + size * 0.10, size * 0.08, accent, 0.98)
    elif kind == "swap":
        draw_hline(img, cx - size * 0.24, cx + size * 0.12, cy - size * 0.08, t, stroke, 0.94)
        draw_line(img, cx + size * 0.12, cy - size * 0.08, cx + size * 0.03, cy - size * 0.16, t * 0.9, stroke, 0.94)
        draw_line(img, cx + size * 0.12, cy - size * 0.08, cx + size * 0.03, cy + size * 0.00, t * 0.9, stroke, 0.94)
        draw_hline(img, cx - size * 0.12, cx + size * 0.24, cy + size * 0.10, t, stroke, 0.94)
        draw_line(img, cx - size * 0.12, cy + size * 0.10, cx - size * 0.02, cy + size * 0.18, t * 0.9, stroke, 0.94)
        draw_line(img, cx - size * 0.12, cy + size * 0.10, cx - size * 0.02, cy + size * 0.02, t * 0.9, stroke, 0.94)
    else:  # "spark"
        draw_circle(img, cx, cy, size * 0.08, accent, 0.98)
        draw_hline(img, cx - size * 0.24, cx + size * 0.24, cy, t * 0.9, stroke, 0.94)
        draw_vline(img, cx, cy - size * 0.24, cy + size * 0.24, t * 0.9, stroke, 0.94)
        draw_line(img, cx - size * 0.16, cy - size * 0.16, cx + size * 0.16, cy + size * 0.16, t * 0.75, stroke, 0.78)
        draw_line(img, cx - size * 0.16, cy + size * 0.16, cx + size * 0.16, cy - size * 0.16, t * 0.75, stroke, 0.78)


def draw_orbit_mark(
    img: Raster,
    cx: float,
    cy: float,
    size: float,
    *,
    ring_outer: tuple[int, int, int],
    ring_inner: tuple[int, int, int],
    top_strip_primary: tuple[int, int, int],
    top_strip_secondary: tuple[int, int, int],
    moon_color: tuple[int, int, int],
    star_color: tuple[int, int, int],
) -> None:
    panel = size * 0.86
    x = cx - panel / 2.0
    y = cy - panel / 2.0
    radius = size * 0.19

    # Night-sky card container.
    draw_rounded_rect(img, x + size * 0.014, y + size * 0.020, panel, panel, radius, (5, 10, 22), 0.55)
    draw_rounded_rect(img, x, y, panel, panel, radius, top_strip_secondary, 1.0)
    draw_rounded_rect(
        img,
        x + size * 0.010,
        y + size * 0.010,
        panel - size * 0.020,
        panel - size * 0.020,
        radius * 0.88,
        top_strip_primary,
        0.70,
    )

    # Moon glow layers.
    moon_r = size * 0.145
    draw_circle(img, cx, cy, moon_r * 2.00, moon_color, 0.14)
    draw_circle(img, cx, cy, moon_r * 1.58, ring_outer, 0.14)
    draw_circle(img, cx, cy, moon_r * 1.18, moon_color, 0.20)
    draw_circle(img, cx, cy, moon_r, ring_outer, 0.98)
    draw_circle(img, cx - moon_r * 0.24, cy + moon_r * 0.22, moon_r * 0.13, ring_inner, 0.56)
    draw_circle(img, cx + moon_r * 0.08, cy - moon_r * 0.14, moon_r * 0.10, ring_inner, 0.48)
    draw_circle(img, cx + moon_r * 0.22, cy + moon_r * 0.03, moon_r * 0.07, ring_inner, 0.42)

    # Star field.
    stars = [
        (-0.28, -0.30, 0.018, 0.95),
        (0.24, -0.36, 0.015, 0.92),
        (-0.34, 0.16, 0.012, 0.88),
        (0.30, 0.08, 0.013, 0.90),
        (0.06, -0.44, 0.010, 0.85),
    ]
    for dx, dy, sr, sa in stars:
        sx = cx + size * dx
        sy = cy + size * dy
        r = size * sr
        draw_circle(img, sx, sy, r, star_color, sa)
        draw_hline(img, sx - r * 1.6, sx + r * 1.6, sy, r * 0.62, star_color, sa * 0.72)
        draw_vline(img, sx, sy - r * 1.6, sy + r * 1.6, r * 0.62, star_color, sa * 0.72)

    # Four corner feature chips + feature symbols.
    chip = size * 0.14
    chip_r = size * 0.032
    offset = size * 0.29
    chip_positions = [(-offset, -offset), (offset, -offset), (-offset, offset), (offset, offset)]
    chip_kinds = ["grid", "event", "swap", "spark"]
    for (dx, dy), kind in zip(chip_positions, chip_kinds):
        ccx = cx + dx
        ccy = cy + dy
        draw_rounded_rect(
            img,
            ccx - chip / 2.0,
            ccy - chip / 2.0,
            chip,
            chip,
            chip_r,
            top_strip_secondary,
            0.96,
        )
        draw_rounded_rect(
            img,
            ccx - chip / 2.0 + size * 0.005,
            ccy - chip / 2.0 + size * 0.005,
            chip - size * 0.010,
            chip - size * 0.010,
            chip_r * 0.86,
            top_strip_primary,
            0.72,
        )
        draw_feature_corner_glyph(
            img,
            ccx,
            ccy,
            chip,
            kind=kind,
            stroke=ring_outer,
            accent=star_color,
        )


def render_icon(size: int, palette: IconPalette) -> Raster:
    img = Raster(size, size)
    draw_linear_gradient(img, palette.gradient_tl, palette.gradient_br)
    draw_radial_light(
        img,
        size * 0.26,
        size * 0.2,
        size * 0.62,
        palette.light_a,
        palette.light_a_alpha * 0.75,
    )
    draw_radial_light(
        img,
        size * 0.78,
        size * 0.82,
        size * 0.7,
        palette.light_b,
        palette.light_b_alpha * 0.70,
    )

    # Subtle frame highlight
    draw_rounded_rect(
        img,
        size * 0.055,
        size * 0.055,
        size * 0.89,
        size * 0.89,
        size * 0.22,
        palette.ring_outer,
        0.08,
    )
    draw_rounded_rect(
        img,
        size * 0.035,
        size * 0.035,
        size * 0.93,
        size * 0.93,
        size * 0.24,
        palette.ring_inner,
        0.10,
    )

    draw_orbit_mark(
        img,
        size * 0.5,
        size * 0.5,
        size * 0.88,
        ring_outer=palette.ring_outer,
        ring_inner=palette.ring_inner,
        top_strip_primary=palette.top_strip_primary,
        top_strip_secondary=palette.top_strip_secondary,
        moon_color=palette.moon_color,
        star_color=palette.star_color,
    )
    return img


def render_feature_graphic(width: int, height: int) -> Raster:
    img = Raster(width, height)
    p = ICON_PALETTES["default"]
    draw_linear_gradient(img, (8, 14, 33), (28, 56, 112))
    draw_radial_light(img, width * 0.20, height * 0.12, width * 0.48, p.moon_color, 0.22)
    draw_radial_light(img, width * 0.92, height * 0.78, width * 0.46, (62, 106, 184), 0.26)

    # Ambient stars.
    sky_stars = [
        (0.08, 0.12, 0.006, 0.84),
        (0.16, 0.24, 0.004, 0.72),
        (0.44, 0.10, 0.005, 0.86),
        (0.58, 0.18, 0.004, 0.74),
        (0.74, 0.09, 0.006, 0.84),
        (0.86, 0.22, 0.005, 0.80),
        (0.92, 0.14, 0.004, 0.70),
        (0.68, 0.34, 0.004, 0.66),
    ]
    for sx, sy, sr, sa in sky_stars:
        draw_circle(img, width * sx, height * sy, width * sr, p.ring_outer, sa)

    # Hero logo.
    draw_orbit_mark(
        img,
        width * 0.29,
        height * 0.50,
        min(width, height) * 0.82,
        ring_outer=p.ring_outer,
        ring_inner=p.ring_inner,
        top_strip_primary=p.top_strip_primary,
        top_strip_secondary=p.top_strip_secondary,
        moon_color=p.moon_color,
        star_color=p.star_color,
    )

    # Supporting panel.
    panel_x = width * 0.57
    panel_y = height * 0.12
    panel_w = width * 0.36
    panel_h = height * 0.76
    draw_rounded_rect(img, panel_x + 3, panel_y + 5, panel_w, panel_h, 30, (4, 8, 18), 0.58)
    draw_rounded_rect(img, panel_x, panel_y, panel_w, panel_h, 28, p.top_strip_secondary, 0.86)
    draw_rounded_rect(img, panel_x + 4, panel_y + 4, panel_w - 8, panel_h - 8, 24, p.top_strip_primary, 0.72)

    moon_cx = panel_x + panel_w * 0.50
    moon_cy = panel_y + panel_h * 0.38
    moon_r = panel_h * 0.13
    draw_circle(img, moon_cx, moon_cy, moon_r * 1.90, p.moon_color, 0.16)
    draw_circle(img, moon_cx, moon_cy, moon_r * 1.45, p.ring_outer, 0.16)
    draw_circle(img, moon_cx, moon_cy, moon_r, p.ring_outer, 0.98)
    draw_circle(img, moon_cx - moon_r * 0.23, moon_cy + moon_r * 0.20, moon_r * 0.14, p.ring_inner, 0.52)
    draw_circle(img, moon_cx + moon_r * 0.10, moon_cy - moon_r * 0.13, moon_r * 0.10, p.ring_inner, 0.44)

    # Feature chips row.
    chip_s = panel_w * 0.16
    chip_y = panel_y + panel_h * 0.74
    chip_xs = [
        panel_x + panel_w * 0.18,
        panel_x + panel_w * 0.40,
        panel_x + panel_w * 0.62,
        panel_x + panel_w * 0.84,
    ]
    chip_kinds = ["grid", "event", "swap", "spark"]
    for ccx, kind in zip(chip_xs, chip_kinds):
        draw_rounded_rect(img, ccx - chip_s / 2, chip_y - chip_s / 2, chip_s, chip_s, chip_s * 0.22, p.top_strip_secondary, 0.95)
        draw_rounded_rect(
            img,
            ccx - chip_s / 2 + 2,
            chip_y - chip_s / 2 + 2,
            chip_s - 4,
            chip_s - 4,
            chip_s * 0.20,
            p.top_strip_primary,
            0.74,
        )
        draw_feature_corner_glyph(
            img,
            ccx,
            chip_y,
            chip_s,
            kind=kind,
            stroke=p.ring_outer,
            accent=p.star_color,
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


def run(cmd: list[str]) -> None:
    subprocess.run(cmd, check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)


def resize_png(src: str, size: int, out_path: str) -> None:
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    run(["sips", "-z", str(size), str(size), src, "--out", out_path])


def resize_to_webp(src: str, size: int, out_path: str) -> None:
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    with tempfile.NamedTemporaryFile(suffix=".png", delete=False) as tmp:
        tmp_png = tmp.name
    try:
        resize_png(src, size, tmp_png)
        run(["cwebp", "-q", "92", tmp_png, "-o", out_path])
    finally:
        if os.path.exists(tmp_png):
            os.remove(tmp_png)


def write_text(path: str, content: str) -> None:
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8") as f:
        f.write(content)


def propagate_android_icons(icon_sources: dict[str, str]) -> None:
    base_res = os.path.join(
        ROOT, "apps", "myanmar_calendar", "android", "app", "src", "main", "res"
    )
    anydpi_v26_dir = os.path.join(base_res, "mipmap-anydpi-v26")
    drawable_dir = os.path.join(base_res, "drawable")
    for density, size in ANDROID_MIPMAP_SIZES.items():
        mipmap_dir = os.path.join(base_res, f"mipmap-{density}")
        for key, src_icon in icon_sources.items():
            resource_name = ICON_RESOURCE_NAMES[key]
            legacy_name = f"{resource_name}_legacy"
            resize_to_webp(
                src_icon,
                size,
                os.path.join(mipmap_dir, f"{resource_name}.webp"),
            )
            resize_to_webp(
                src_icon,
                size,
                os.path.join(mipmap_dir, f"{resource_name}_round.webp"),
            )
            resize_to_webp(
                src_icon,
                size,
                os.path.join(mipmap_dir, f"{legacy_name}.webp"),
            )
            resize_to_webp(
                src_icon,
                size,
                os.path.join(mipmap_dir, f"{legacy_name}_round.webp"),
            )

    # Generate adaptive icon xml for each variant to avoid launcher fallback icons.
    for resource_name in ICON_RESOURCE_NAMES.values():
        legacy_name = f"{resource_name}_legacy"
        foreground_name = f"{resource_name}_foreground"
        foreground_round_name = f"{resource_name}_foreground_round"

        # Inset keeps icon artwork inside adaptive safe-zone and avoids zoomed look.
        foreground_xml = f"""<?xml version="1.0" encoding="utf-8"?>
<inset xmlns:android="http://schemas.android.com/apk/res/android"
    android:inset="16%">
    <bitmap
        android:gravity="center"
        android:src="@mipmap/{legacy_name}" />
</inset>
"""
        foreground_round_xml = f"""<?xml version="1.0" encoding="utf-8"?>
<inset xmlns:android="http://schemas.android.com/apk/res/android"
    android:inset="16%">
    <bitmap
        android:gravity="center"
        android:src="@mipmap/{legacy_name}_round" />
</inset>
"""
        write_text(
            os.path.join(drawable_dir, f"{foreground_name}.xml"),
            foreground_xml,
        )
        write_text(
            os.path.join(drawable_dir, f"{foreground_round_name}.xml"),
            foreground_round_xml,
        )

        adaptive_xml = f"""<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/{foreground_name}"/>
</adaptive-icon>
"""
        adaptive_round_xml = f"""<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background"/>
    <foreground android:drawable="@drawable/{foreground_round_name}"/>
</adaptive-icon>
"""
        write_text(
            os.path.join(anydpi_v26_dir, f"{resource_name}.xml"),
            adaptive_xml,
        )
        write_text(
            os.path.join(anydpi_v26_dir, f"{resource_name}_round.xml"),
            adaptive_round_xml,
        )


def populate_iconset_from_reference(
    *,
    source_icon_1024: str,
    reference_iconset_dir: str,
    target_iconset_dir: str,
) -> None:
    os.makedirs(target_iconset_dir, exist_ok=True)
    src_contents = os.path.join(reference_iconset_dir, "Contents.json")
    dst_contents = os.path.join(target_iconset_dir, "Contents.json")
    if os.path.exists(src_contents):
        with open(src_contents, encoding="utf-8") as f:
            raw_contents = json.load(f)
        raw_images = raw_contents.get("images", [])
        sanitized_images: list[dict[str, str]] = []
        for image in raw_images:
            if not isinstance(image, dict):
                continue
            sanitized = {
                key: image[key]
                for key in _IOS_ICONSET_ALLOWED_KEYS
                if key in image
            }
            if "idiom" not in sanitized or "size" not in sanitized:
                continue
            sanitized_images.append(sanitized)
        normalized_contents = {
            "images": sanitized_images,
            "info": {"version": 1, "author": "xcode"},
        }
        with open(dst_contents, "w", encoding="utf-8") as f:
            json.dump(normalized_contents, f, ensure_ascii=False, indent=2)
            f.write("\n")
    for name in os.listdir(reference_iconset_dir):
        if not name.endswith(".png"):
            continue
        stem = name[:-4]
        if not stem.isdigit():
            continue
        size = int(stem)
        resize_png(source_icon_1024, size, os.path.join(target_iconset_dir, name))


def propagate_ios_macos_icons(icon_sources: dict[str, str]) -> None:
    ios_assets = os.path.join(
        ROOT, "apps", "myanmar_calendar", "ios", "Runner", "Assets.xcassets"
    )
    ios_primary_iconset = os.path.join(ios_assets, "AppIcon.appiconset")
    macos_primary_iconset = os.path.join(
        ROOT,
        "apps",
        "myanmar_calendar",
        "macos",
        "Runner",
        "Assets.xcassets",
        "AppIcon.appiconset",
    )

    populate_iconset_from_reference(
        source_icon_1024=icon_sources["default"],
        reference_iconset_dir=ios_primary_iconset,
        target_iconset_dir=ios_primary_iconset,
    )
    populate_iconset_from_reference(
        source_icon_1024=icon_sources["default"],
        reference_iconset_dir=macos_primary_iconset,
        target_iconset_dir=macos_primary_iconset,
    )

    # iOS alternate launcher icons.
    for key, iconset_name in IOS_ALT_ICONSET_NAMES.items():
        populate_iconset_from_reference(
            source_icon_1024=icon_sources[key],
            reference_iconset_dir=ios_primary_iconset,
            target_iconset_dir=os.path.join(ios_assets, f"{iconset_name}.appiconset"),
        )


def propagate_web_icons(src_icon_1024: str) -> None:
    web_dir = os.path.join(ROOT, "apps", "myanmar_calendar", "web")
    icons_dir = os.path.join(web_dir, "icons")
    resize_png(src_icon_1024, 192, os.path.join(icons_dir, "android-chrome-192x192.png"))
    resize_png(src_icon_1024, 512, os.path.join(icons_dir, "android-chrome-512x512.png"))
    resize_png(src_icon_1024, 180, os.path.join(icons_dir, "apple-touch-icon.png"))
    resize_png(src_icon_1024, 16, os.path.join(icons_dir, "favicon-16x16.png"))
    resize_png(src_icon_1024, 32, os.path.join(icons_dir, "favicon-32x32.png"))

    # Root favicon.ico
    run(
        [
            "ffmpeg",
            "-y",
            "-i",
            src_icon_1024,
            "-vf",
            "scale=32:32",
            os.path.join(web_dir, "favicon.ico"),
        ]
    )


def main() -> None:
    rendered_icons = {
        key: render_icon(1024, palette) for key, palette in ICON_PALETTES.items()
    }
    feature = render_feature_graphic(1024, 500)

    icon_master_paths = {
        key: os.path.join(
            ROOT,
            "apps",
            "myanmar_calendar",
            "assets",
            "branding",
            filename,
        )
        for key, filename in ICON_MASTER_FILENAMES.items()
    }
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

    for key, raster in rendered_icons.items():
        write_png(raster, icon_master_paths[key])
    resize_png(icon_master_paths["default"], 512, logo_app_path)
    resize_png(icon_master_paths["default"], 512, logo_root_path)
    resize_png(icon_master_paths["default"], 512, play_store_icon_path)
    write_png(feature, feature_path)
    write_png(feature, screenshot_feature_path)
    propagate_android_icons(icon_master_paths)
    propagate_ios_macos_icons(icon_master_paths)
    propagate_web_icons(icon_master_paths["default"])

    print("Generated brand assets:")
    for key in ICON_MASTER_FILENAMES.keys():
        print(f"- {icon_master_paths[key]}")
    print(f"- {feature_path}")
    print(f"- {logo_app_path}")
    print(f"- {logo_root_path}")
    print(f"- {play_store_icon_path}")
    print(f"- {screenshot_feature_path}")
    print("- Android mipmap icons (mdpi..xxxhdpi) + adaptive xml")
    print("- iOS/macOS AppIcon appiconset PNG files")
    print("- Web icons + favicon.ico")


if __name__ == "__main__":
    main()
