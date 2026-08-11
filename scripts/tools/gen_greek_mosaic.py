#!/usr/bin/env python3
"""Generate a Greek pebble PAVEMENT texture (ψηφιδωτό) for plaza floors.

Unlike a heraldic medallion / shield emblem, this is dense pebble paving with
subtle meander and wave bands — closer to Olynthos / Pella courtyard floors.
Designed to TILE across a plaza (not one giant logo on the disc).
"""
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageFilter

SIZE = 1024
OUT = Path(__file__).resolve().parents[2] / "assets/textures/stone/greek_pebble_mosaic.png"
SEED = 20260811

CREAM = [(198, 176, 148), (182, 162, 134), (170, 154, 126), (208, 186, 158)]
TERRACOTTA = [(118, 62, 42), (98, 50, 34), (132, 72, 48)]
CHARCOAL = [(42, 38, 34), (55, 48, 42), (32, 30, 28)]
OCHRE = [(148, 112, 58), (130, 98, 48), (160, 122, 66)]
SLATE = [(70, 80, 88), (58, 68, 78)]
GROUT = (52, 46, 40)


def pick(rng: random.Random, palette: list[tuple[int, int, int]]) -> tuple[int, int, int]:
    c = list(palette[rng.randrange(len(palette))])
    j = rng.randint(-8, 8)
    return tuple(max(0, min(255, ch + j)) for ch in c)  # type: ignore[return-value]


def stamp(
    px,
    cx: int,
    cy: int,
    rx: float,
    ry: float,
    col: tuple[int, int, int],
) -> None:
    for dy in range(int(-ry - 1), int(ry + 2)):
        for dx in range(int(-rx - 1), int(rx + 2)):
            nx = (cx + dx) % SIZE
            ny = (cy + dy) % SIZE
            if (dx * dx) / max(0.01, rx * rx) + (dy * dy) / max(0.01, ry * ry) <= 1.0:
                px[nx, ny] = col


def pebble_field(img: Image.Image, rng: random.Random) -> None:
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            g = GROUT[0] + rng.randint(-5, 5)
            px[x, y] = (g, max(0, g - 4), max(0, g - 8))
    # Dense irregular pebbles — reads as worn courtyard paving.
    for _ in range(42000):
        cx = rng.randrange(SIZE)
        cy = rng.randrange(SIZE)
        rx = rng.uniform(1.6, 3.8)
        ry = rng.uniform(1.3, 3.4)
        roll = rng.random()
        if roll < 0.78:
            col = pick(rng, CREAM)
        elif roll < 0.88:
            col = pick(rng, OCHRE)
        elif roll < 0.94:
            col = pick(rng, TERRACOTTA)
        elif roll < 0.97:
            col = pick(rng, SLATE)
        else:
            col = pick(rng, CHARCOAL)
        stamp(px, cx, cy, rx, ry, col)


def horizontal_meander_band(
    img: Image.Image,
    rng: random.Random,
    y0: int,
    band_h: int,
    unit_w: int,
) -> None:
    """Straight Greek-key strip (floor border), not a circular shield emblem."""
    px = img.load()
    y1 = y0 + band_h
    # Dark band underlay
    for y in range(y0, y1):
        for x in range(SIZE):
            if rng.random() < 0.9:
                stamp(px, x, y, 2.0, 1.8, pick(rng, CHARCOAL))

    cream = CREAM
    mid = y0 + band_h // 2
    top = y0 + 3
    bot = y1 - 4
    x = 0
    while x < SIZE:
        # Classic square meander unit along X
        for t in range(unit_w // 2):
            stamp(px, (x + t) % SIZE, top, 2.2, 1.8, pick(rng, cream))
        for t in range(band_h - 6):
            stamp(px, (x + unit_w // 2) % SIZE, top + t, 2.0, 1.8, pick(rng, cream))
        for t in range(unit_w // 4):
            stamp(px, (x + unit_w // 2 + t) % SIZE, bot, 2.2, 1.8, pick(rng, cream))
        for t in range(band_h - 6):
            stamp(px, (x + unit_w // 2 + unit_w // 4) % SIZE, bot - t, 2.0, 1.8, pick(rng, cream))
        for t in range(unit_w // 4):
            stamp(px, (x + unit_w // 2 + unit_w // 4 + t) % SIZE, top, 2.2, 1.8, pick(rng, cream))
        x += unit_w


def wave_band(img: Image.Image, rng: random.Random, y_mid: int, amp: int, waves: int) -> None:
    px = img.load()
    for i in range(SIZE * 2):
        x = i // 2
        a = (x / SIZE) * math.tau * waves
        y = int(y_mid + math.sin(a) * amp)
        stamp(px, x % SIZE, y % SIZE, 2.4, 2.0, pick(rng, TERRACOTTA if i % 3 else OCHRE))


def terracotta_grid_accent(img: Image.Image, rng: random.Random, step: int) -> None:
    """Faint tessera grid — reads as laid paving, not a crest."""
    px = img.load()
    for y in range(0, SIZE, step):
        for x in range(SIZE):
            if rng.random() < 0.35:
                stamp(px, x, y, 1.6, 1.4, pick(rng, TERRACOTTA))
    for x in range(0, SIZE, step):
        for y in range(SIZE):
            if rng.random() < 0.35:
                stamp(px, x, y, 1.4, 1.6, pick(rng, TERRACOTTA))


def main() -> None:
    rng = random.Random(SEED)
    img = Image.new("RGB", (SIZE, SIZE), GROUT)
    pebble_field(img, rng)
    terracotta_grid_accent(img, rng, 64)
    # Two meander borders + a soft wave — courtyard floor language
    horizontal_meander_band(img, rng, 72, 48, 64)
    horizontal_meander_band(img, rng, SIZE - 120, 48, 64)
    wave_band(img, rng, SIZE // 2, 18, 6)
    img = img.filter(ImageFilter.SMOOTH_MORE)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, optimize=True)
    print(f"Wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
