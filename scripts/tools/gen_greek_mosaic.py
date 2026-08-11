#!/usr/bin/env python3
"""Generate an ancient-Greek pebble mosaic (ψηφιδωτό) texture.

Palette inspired by Pella / Olynthos pebble mosaics: cream limestone,
terracotta, charcoal, ochre, muted slate — darker than white marble.
Produces a circular court design (meander + wave + star medallion) for
the Thermopolis fountain plaza.
"""
from __future__ import annotations

import math
import random
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
OUT = Path(__file__).resolve().parents[2] / "assets/textures/stone/greek_pebble_mosaic.png"
SEED = 20260811

CREAM = [(200, 178, 145), (185, 165, 132), (175, 158, 128), (210, 188, 155)]
TERRACOTTA = [(130, 65, 42), (110, 52, 36), (145, 78, 50), (95, 45, 32)]
CHARCOAL = [(38, 34, 30), (50, 44, 38), (28, 26, 24), (62, 52, 44)]
OCHRE = [(150, 110, 50), (135, 98, 44), (165, 122, 58)]
SLATE = [(65, 78, 88), (50, 64, 76), (78, 88, 92)]
GROUT = (48, 42, 36)


def pick(rng: random.Random, palette: list[tuple[int, int, int]]) -> tuple[int, int, int]:
    c = list(palette[rng.randrange(len(palette))])
    j = rng.randint(-10, 10)
    return tuple(max(0, min(255, ch + j)) for ch in c)  # type: ignore[return-value]


def stamp_pebble(
    px,
    cx: int,
    cy: int,
    rx: float,
    ry: float,
    col: tuple[int, int, int],
    size: int = SIZE,
) -> None:
    for dy in range(int(-ry - 1), int(ry + 2)):
        for dx in range(int(-rx - 1), int(rx + 2)):
            nx = cx + dx
            ny = cy + dy
            if nx < 0 or ny < 0 or nx >= size or ny >= size:
                continue
            if (dx * dx) / (rx * rx) + (dy * dy) / (ry * ry) <= 1.0:
                px[nx, ny] = col


def fill_pebble_field(img: Image.Image, rng: random.Random) -> None:
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            g = GROUT[0] + rng.randint(-6, 6)
            px[x, y] = (g, max(0, g - 4), max(0, g - 8))

    for _ in range(28000):
        cx = rng.randrange(SIZE)
        cy = rng.randrange(SIZE)
        rx = rng.uniform(2.0, 4.8)
        ry = rng.uniform(1.6, 4.2)
        roll = rng.random()
        if roll < 0.80:
            col = pick(rng, CREAM)
        elif roll < 0.90:
            col = pick(rng, OCHRE)
        elif roll < 0.95:
            col = pick(rng, TERRACOTTA)
        elif roll < 0.98:
            col = pick(rng, SLATE)
        else:
            col = pick(rng, CHARCOAL)
        stamp_pebble(px, cx, cy, rx, ry, col)


def paint_annulus(
    img: Image.Image,
    rng: random.Random,
    cx: float,
    cy: float,
    r0: float,
    r1: float,
    palette: list[tuple[int, int, int]],
    density: float = 0.7,
) -> None:
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            r = math.hypot(x - cx, y - cy)
            if r0 <= r < r1 and rng.random() < density:
                stamp_pebble(px, x, y, rng.uniform(1.8, 3.6), rng.uniform(1.5, 3.2), pick(rng, palette))


def greek_key_ring(
    img: Image.Image,
    rng: random.Random,
    cx: float,
    cy: float,
    r_inner: float,
    band: float,
    n_units: int,
    palette: list[tuple[int, int, int]],
) -> None:
    """Classic square meander (Greek key) along a circular ring."""
    px = img.load()
    r_outer = r_inner + band
    r_mid = (r_inner + r_outer) * 0.5
    # Fill band with charcoal base pebbles first
    paint_annulus(img, rng, cx, cy, r_inner, r_outer, palette, 0.85)

    # Draw the key path as cream tesserae so the pattern reads clearly
    cream = CREAM
    for i in range(n_units):
        a0 = (i / n_units) * math.tau
        a1 = ((i + 0.45) / n_units) * math.tau
        a2 = ((i + 0.55) / n_units) * math.tau
        a3 = ((i + 1.0) / n_units) * math.tau

        def arc_pebbles(ra: float, aa: float, ab: float, steps: int = 14) -> None:
            for s in range(steps):
                t = s / max(1, steps - 1)
                a = aa + (ab - aa) * t
                x = int(cx + math.cos(a) * ra)
                y = int(cy + math.sin(a) * ra)
                stamp_pebble(px, x, y, 2.4, 2.0, pick(rng, cream))

        def radial_pebbles(a: float, r0: float, r1: float, steps: int = 10) -> None:
            for s in range(steps):
                t = s / max(1, steps - 1)
                rr = r0 + (r1 - r0) * t
                x = int(cx + math.cos(a) * rr)
                y = int(cy + math.sin(a) * rr)
                stamp_pebble(px, x, y, 2.4, 2.0, pick(rng, cream))

        # Outer run → inward → inner run → outward (classic key unit)
        arc_pebbles(r_outer - 3, a0, a1)
        radial_pebbles(a1, r_outer - 3, r_inner + 3)
        arc_pebbles(r_inner + 3, a1, a2)
        radial_pebbles(a2, r_inner + 3, r_outer - 3)
        arc_pebbles(r_outer - 3, a2, a3)


def wave_ring(
    img: Image.Image,
    rng: random.Random,
    cx: float,
    cy: float,
    r: float,
    amp: float,
    waves: int,
    palette: list[tuple[int, int, int]],
    width: float = 6.0,
) -> None:
    px = img.load()
    steps = 720
    for i in range(steps):
        a = (i / steps) * math.tau
        rr = r + math.sin(a * waves) * amp
        x = int(cx + math.cos(a) * rr)
        y = int(cy + math.sin(a) * rr)
        stamp_pebble(px, x, y, width * 0.45, width * 0.4, pick(rng, palette))


def central_star(
    img: Image.Image,
    rng: random.Random,
    cx: float,
    cy: float,
    r: float,
) -> None:
    px = img.load()
    # Dark disc underlay
    paint_annulus(img, rng, cx, cy, 0.0, r, CHARCOAL, 0.9)
    # 8-point star in terracotta
    outer = r * 0.88
    inner = r * 0.36
    for y in range(int(cy - outer), int(cy + outer) + 1):
        for x in range(int(cx - outer), int(cx + outer) + 1):
            dx = x - cx
            dy = y - cy
            ang = math.atan2(dy, dx)
            # map angle to star radius
            # 8 points → period pi/4
            local = (ang + math.pi / 2) % (math.pi / 4)
            # distance from point axis
            t = abs(local - math.pi / 8) / (math.pi / 8)
            rad = outer * (1.0 - t) + inner * t
            if math.hypot(dx, dy) <= rad:
                stamp_pebble(px, x, y, 2.2, 1.9, pick(rng, TERRACOTTA))
    # cream centre
    paint_annulus(img, rng, cx, cy, 0.0, r * 0.18, CREAM, 0.95)
    paint_annulus(img, rng, cx, cy, 0.0, r * 0.07, CHARCOAL, 1.0)


def main() -> None:
    rng = random.Random(SEED)
    img = Image.new("RGB", (SIZE, SIZE), GROUT)
    fill_pebble_field(img, rng)

    cx = cy = SIZE * 0.5

    # Outer charcoal frame band
    paint_annulus(img, rng, cx, cy, SIZE * 0.47, SIZE * 0.495, CHARCOAL, 0.9)

    # Outer Greek key
    greek_key_ring(img, rng, cx, cy, SIZE * 0.40, SIZE * 0.055, 24, CHARCOAL)

    # Cream separator
    paint_annulus(img, rng, cx, cy, SIZE * 0.375, SIZE * 0.395, CREAM, 0.8)

    # Wave (kyma) ring in terracotta on cream field
    paint_annulus(img, rng, cx, cy, SIZE * 0.30, SIZE * 0.37, CREAM, 0.55)
    wave_ring(img, rng, cx, cy, SIZE * 0.335, SIZE * 0.016, 16, TERRACOTTA, 7.0)

    # Inner Greek key
    greek_key_ring(img, rng, cx, cy, SIZE * 0.22, SIZE * 0.045, 16, CHARCOAL)

    # Central medallion
    central_star(img, rng, cx, cy, SIZE * 0.185)

    img = img.filter(ImageFilter.SMOOTH)

    # Overall darken so the plaza doesn't blow out in Mediterranean sun
    px = img.load()
    for y in range(SIZE):
        for x in range(SIZE):
            r, g, b = px[x, y]
            px[x, y] = (int(r * 0.86), int(g * 0.84), int(b * 0.80))

    OUT.parent.mkdir(parents=True, exist_ok=True)
    img.save(OUT, format="PNG", optimize=True)
    print(f"wrote {OUT} ({OUT.stat().st_size} bytes)")


if __name__ == "__main__":
    main()
