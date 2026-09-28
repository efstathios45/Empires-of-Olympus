#!/usr/bin/env python3
"""Build distinct 96×96 inventory icons under assets/ui/items/."""
from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "ui" / "items"
SIZE = 96


def thumb_from(src: Path, dest: Path) -> None:
    im = Image.open(src).convert("RGBA")
    im.thumbnail((SIZE * 2, SIZE * 2), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    x = (SIZE - im.width) // 2
    y = (SIZE - im.height) // 2
    canvas.paste(im, (x, y), im)
    dest.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(dest, "PNG")


def stylized(dest: Path, base_rgb: tuple, draw_fn) -> None:
    im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    draw_fn(d, im)
    # Soft vignette background
    bg_fill = (int(base_rgb[0] * 255), int(base_rgb[1] * 255), int(base_rgb[2] * 255), 255)
    bg = Image.new("RGBA", (SIZE, SIZE), bg_fill)
    mask = Image.new("L", (SIZE, SIZE), 0)
    md = ImageDraw.Draw(mask)
    md.rounded_rectangle((4, 4, SIZE - 4, SIZE - 4), radius=12, fill=220)
    bg.putalpha(mask)
    im = Image.alpha_composite(bg, im)
    im = im.filter(ImageFilter.SMOOTH)
    dest.parent.mkdir(parents=True, exist_ok=True)
    im.save(dest, "PNG")


def main() -> None:
    gear = ROOT / "assets" / "props" / "gear"
    ui = ROOT / "assets" / "ui"
    mapping = [
        (gear / "xiphos_sword_0.png", OUT / "icon_xiphos.png"),
        (gear / "kontos_spear_0.png", OUT / "icon_kontos.png"),
        (gear / "aspis_shield_0.png", OUT / "icon_aspis.png"),
        (gear / "tower_aspis_face.png", OUT / "icon_tower_shield.png"),
        (ui / "icon_sword.png", OUT / "icon_bow.png"),
    ]
    for src, dest in mapping:
        if src.is_file():
            thumb_from(src, dest)

    # Machaira — tinted xiphos thumb
    xiph = OUT / "icon_xiphos.png"
    if xiph.is_file():
        im = Image.open(xiph).convert("RGBA")
        r, g, b, a = im.split()
        im = Image.merge(
            "RGBA",
            (
                r.point(lambda p: min(255, int(p * 1.05))),
                g.point(lambda p: int(p * 0.75)),
                b.point(lambda p: int(p * 0.55)),
                a,
            ),
        )
        im.save(OUT / "icon_machaira.png", "PNG")

    def helm_draw(d: ImageDraw.ImageDraw, _im: Image.Image) -> None:
        d.polygon(
            [(48, 14), (72, 38), (68, 72), (28, 72), (24, 38)],
            fill=(184, 133, 56, 255),
            outline=(89, 64, 31, 255),
        )
        d.rectangle((30, 52, 66, 58), fill=(38, 31, 26, 255))
        d.line([(48, 14), (48, 8)], fill=(217, 51, 38, 255), width=3)

    stylized(OUT / "icon_corinthian_helm.png", (0.25, 0.2, 0.15), helm_draw)

    def cuirass_draw(d: ImageDraw.ImageDraw, _im: Image.Image) -> None:
        d.rounded_rectangle((32, 22, 64, 78), radius=8, fill=(107, 71, 46, 255))
        d.line([(48, 26), (48, 74)], fill=(77, 51, 31, 255), width=2)

    stylized(OUT / "icon_leather_cuirass.png", (0.2, 0.16, 0.12), cuirass_draw)

    def thorax_draw(d: ImageDraw.ImageDraw, _im: Image.Image) -> None:
        d.rounded_rectangle((30, 20, 66, 80), radius=10, fill=(191, 140, 64, 255))
        d.ellipse((38, 28, 52, 44), outline=(115, 82, 38, 255), width=2)
        d.ellipse((44, 28, 58, 44), outline=(115, 82, 38, 255), width=2)

    stylized(OUT / "icon_bronze_thorax.png", (0.22, 0.18, 0.14), thorax_draw)

    def sandal_draw(d: ImageDraw.ImageDraw, _im: Image.Image) -> None:
        d.ellipse((22, 48, 74, 82), fill=(122, 82, 46, 255))
        for x in (32, 48, 64):
            d.line([(x, 48), (x, 78)], fill=(89, 56, 31, 255), width=2)

    stylized(OUT / "icon_leather_sandals.png", (0.18, 0.14, 0.1), sandal_draw)

    def greaves_draw(d: ImageDraw.ImageDraw, _im: Image.Image) -> None:
        d.rounded_rectangle((28, 24, 42, 78), radius=6, fill=(184, 133, 61, 255))
        d.rounded_rectangle((54, 24, 68, 78), radius=6, fill=(184, 133, 61, 255))

    stylized(OUT / "icon_bronze_greaves.png", (0.2, 0.16, 0.12), greaves_draw)

    mats = {
        "icon_mat_wolf_pelt.png": ((0.45, 0.38, 0.32), "W"),
        "icon_mat_boar_tusk.png": ((0.82, 0.76, 0.62), "T"),
        "icon_mat_satyr_horn.png": ((0.55, 0.42, 0.22), "H"),
        "icon_mat_harpy_feather.png": ((0.55, 0.62, 0.78), "F"),
        "icon_mat_centaur_hoof.png": ((0.35, 0.28, 0.22), "C"),
    }
    for name, (rgb, letter) in mats.items():
        im = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        fill = (int(rgb[0] * 255), int(rgb[1] * 255), int(rgb[2] * 255), 255)
        d.rounded_rectangle((20, 20, 76, 76), radius=14, fill=fill)
        d.text((36, 30), letter, fill=(255, 255, 255, 255))
        (OUT / name).parent.mkdir(parents=True, exist_ok=True)
        im.save(OUT / name, "PNG")

    print("Generated icons in", OUT)


if __name__ == "__main__":
    main()
