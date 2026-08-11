#!/usr/bin/env python3
"""Tileable Greek tessera pavement (ψηφιδωτό) — courtyard floor, not a shield.

Square stone chips + seamless Greek-key (meander) borders + running-wave band.
Inspired by Olynthos / Pella pebble floors.
"""
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageFilter

SIZE = 1024
OUT = Path(__file__).resolve().parents[2] / "assets/textures/stone/greek_pebble_mosaic.png"
SEED = 20260812

CREAM = [(214, 196, 168), (200, 182, 154), (188, 172, 146), (222, 204, 176), (196, 178, 150)]
TERRACOTTA = [(148, 78, 52), (126, 64, 42), (160, 90, 60), (110, 54, 36)]
CHARCOAL = [(36, 32, 28), (48, 42, 36), (26, 24, 22)]
OCHRE = [(170, 130, 74), (150, 114, 60), (182, 142, 84)]
SLATE = [(70, 82, 90), (56, 68, 78), (86, 96, 102)]
GROUT = (58, 50, 42)


def pick(rng: random.Random, palette: list[tuple[int, int, int]]) -> tuple[int, int, int]:
    c = list(palette[rng.randrange(len(palette))])
    j = rng.randint(-9, 9)
    return tuple(max(0, min(255, ch + j)) for ch in c)  # type: ignore[return-value]


def put(px, x: int, y: int, col: tuple[int, int, int]) -> None:
    px[x % SIZE, y % SIZE] = col


def stamp_disc(px, cx: int, cy: int, r: float, col: tuple[int, int, int]) -> None:
    ir = int(r) + 1
    for dy in range(-ir, ir + 1):
        for dx in range(-ir, ir + 1):
            if dx * dx + dy * dy <= r * r:
                put(px, cx + dx, cy + dy, col)


def fill_tesserae(img: Image.Image, rng: random.Random, cell: int = 6) -> None:
    px = img.load()
    for y in range(0, SIZE, cell):
        for x in range(0, SIZE, cell):
            w = max(3, cell + rng.randint(-1, 2))
            h = max(3, cell + rng.randint(-1, 2))
            roll = rng.random()
            if roll < 0.70:
                col = pick(rng, CREAM)
            elif roll < 0.80:
                col = pick(rng, OCHRE)
            elif roll < 0.88:
                col = pick(rng, SLATE)
            elif roll < 0.95:
                col = pick(rng, TERRACOTTA)
            else:
                col = pick(rng, CHARCOAL)
            for dy in range(h):
                for dx in range(w):
                    xx = (x + dx) % SIZE
                    yy = (y + dy) % SIZE
                    if dx == 0 or dy == 0:
                        g = GROUT[0] + rng.randint(-8, 8)
                        px[xx, yy] = (g, max(0, g - 6), max(0, g - 10))
                    else:
                        px[xx, yy] = col


def paint_meander_band(img: Image.Image, rng: random.Random, y0: int, band_h: int, unit: int) -> None:
    """Seamless Greek key: continuous square spiral border."""
    px = img.load()
    # Charcoal band fill
    for y in range(y0, y0 + band_h):
        for x in range(SIZE):
            put(px, x, y, pick(rng, CHARCOAL))

    top = y0 + 6
    bot = y0 + band_h - 7
    mid_t = y0 + band_h // 2 - 4
    mid_b = y0 + band_h // 2 + 4
    thick = 4

    def hline(x0: int, x1: int, y: int) -> None:
        if x1 < x0:
            x0, x1 = x1, x0
        for x in range(x0, x1 + 1):
            for t in range(-(thick // 2), thick // 2 + 1):
                put(px, x, y + t, pick(rng, CREAM))

    def vline(y_a: int, y_b: int, x: int) -> None:
        if y_b < y_a:
            y_a, y_b = y_b, y_a
        for y in range(y_a, y_b + 1):
            for t in range(-(thick // 2), thick // 2 + 1):
                put(px, x + t, y, pick(rng, CREAM))

    x = 0
    while x < SIZE:
        # ┌──┐  └── pattern (classic meander unit)
        hline(x, x + unit // 2, top)
        vline(top, bot, x + unit // 2)
        hline(x + unit // 2, x + unit // 2 + unit // 4, bot)
        vline(bot, top, x + unit // 2 + unit // 4)
        hline(x + unit // 2 + unit // 4, x + unit, top)
        # Inner return stroke for denser key
        hline(x + 4, x + unit // 2 - 4, mid_t)
        vline(mid_t, mid_b, x + unit // 2 - 4)
        hline(x + unit // 2 - 4, x + unit // 2 + unit // 4 + 4, mid_b)
        x += unit


def running_wave(img: Image.Image, rng: random.Random, y_mid: int, amp: int, waves: int) -> None:
    px = img.load()
    for x in range(SIZE):
        a = (x / SIZE) * math.tau * waves
        y = int(y_mid + math.sin(a) * amp)
        col = pick(rng, TERRACOTTA if x % 2 == 0 else OCHRE)
        stamp_disc(px, x, y, 2.6, col)
        stamp_disc(px, x, y + 5, 1.8, pick(rng, CHARCOAL))


def main() -> None:
    rng = random.Random(SEED)
    img = Image.new("RGB", (SIZE, SIZE), GROUT)
    fill_tesserae(img, rng, cell=6)
    paint_meander_band(img, rng, 40, 64, 64)
    paint_meander_band(img, rng, SIZE - 104, 64, 64)
    running_wave(img, rng, SIZE // 2, 16, 8)
    img = img.filter(ImageFilter.SMOOTH)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, optimize=True)
    print(f"Wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
