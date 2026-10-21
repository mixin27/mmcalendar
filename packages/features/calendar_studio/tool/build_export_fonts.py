"""Static font instances for Calendar Studio's editable PDF export.

The pdf package embeds TrueType outlines as they are and cannot apply a
variable font's axes, so every weight would come out at the font's default.
This writes one static file per family, weight and style from the bundled
variable fonts, with every other axis pinned to its default (as Flutter
renders it). The app downloads them on demand; they are not bundled.

    pip install fonttools
    python3 tool/build_export_fonts.py ../../../apps/myanmar_calendar/web/export-fonts

File names: <font id>-<weight>[-italic].ttf, e.g. fraunces-600-italic.ttf,
matching CalendarStudioExportFonts.fileName.
"""

import pathlib
import sys

from fontTools.ttLib import TTFont
from fontTools.varLib import instancer

FONTS = pathlib.Path(__file__).resolve().parent.parent / "assets" / "fonts"
WEIGHTS = (400, 500, 600, 700)

# Font id (CalendarStudioFontCatalog) -> (folder, roman file, italic file).
VARIABLE = {
    "cormorant-garamond": ("cormorantgaramond", "CormorantGaramond-Variable.ttf", "CormorantGaramond-Italic-Variable.ttf"),
    "fraunces": ("fraunces", "Fraunces-Variable.ttf", "Fraunces-Italic-Variable.ttf"),
    "bricolage-grotesque": ("bricolagegrotesque", "BricolageGrotesque-Variable.ttf", None),
    "space-grotesk": ("spacegrotesk", "SpaceGrotesk-Variable.ttf", None),
    "libre-caslon-text": ("librecaslontext", "LibreCaslonText-Variable.ttf", None),
    "lora": ("lora", "Lora-Variable.ttf", None),
    "sora": ("sora", "Sora-Variable.ttf", None),
    "newsreader": ("newsreader", "Newsreader-Variable.ttf", "Newsreader-Italic-Variable.ttf"),
    "crimson-pro": ("crimsonpro", "CrimsonPro-Variable.ttf", None),
    "petrona": ("petrona", "Petrona-Variable.ttf", None),
    "bitter": ("bitter", "Bitter-Variable.ttf", None),
}


STYLES = {400: "Regular", 500: "Medium", 600: "SemiBold", 700: "Bold"}


def instance(source: pathlib.Path, weight: int) -> TTFont:
    font = TTFont(source)
    axes = {axis.axisTag: axis.defaultValue for axis in font["fvar"].axes}
    wght = next(a for a in font["fvar"].axes if a.axisTag == "wght")
    axes["wght"] = min(max(weight, wght.minValue), wght.maxValue)
    return instancer.instantiateVariableFont(font, axes)


def rename(font: TTFont, family: str, weight: int, italic: bool) -> None:
    """Plain names, as Illustrator lists them: "Fraunces Medium Italic"."""
    style = STYLES[weight]
    if italic:
        style = "Italic" if style == "Regular" else f"{style} Italic"
    full = family if style == "Regular" else f"{family} {style}"
    postscript = f"{family}-{style}".replace(" ", "")
    legacy_style = "Italic" if italic else "Regular"
    legacy_family = family if style in ("Regular", "Italic") else f"{family} {STYLES[weight]}"
    names = font["name"]
    for record in list(names.names):
        if record.nameID in (1, 2, 3, 4, 6, 16, 17, 21, 22, 25):
            names.removeNames(nameID=record.nameID)
    for name_id, value in {
        1: legacy_family,
        2: legacy_style,
        3: f"{postscript};calendar-studio-export",
        4: full,
        6: postscript,
        16: family,
        17: style,
    }.items():
        names.setName(value, name_id, 3, 1, 0x409)
    font["OS/2"].usWeightClass = weight


def main(out: str) -> None:
    target = pathlib.Path(out)
    target.mkdir(parents=True, exist_ok=True)
    for font_id, (folder, roman, italic) in VARIABLE.items():
        for suffix, file in (("", roman), ("-italic", italic)):
            if file is None:
                continue
            for weight in WEIGHTS:
                name = f"{font_id}-{weight}{suffix}.ttf"
                font = instance(FONTS / folder / file, weight)
                family = TTFont(FONTS / folder / file)["name"].getBestFamilyName()
                rename(font, family, weight, italic=bool(suffix))
                font.save(target / name)
                print(name)


if __name__ == "__main__":
    main(sys.argv[1])
