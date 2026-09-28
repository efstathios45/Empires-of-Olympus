#!/usr/bin/env python3
"""Build 256² inventory icons: GLB studio renders + game UI art (CC0 / in-house)."""
from __future__ import annotations

import shutil
import subprocess
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets/ui/items"
UI = ROOT / "assets/ui"
GEAR = ROOT / "assets/props/gear"
SIZE = 256
PAD = 0.08


def trim_alpha(im: Image.Image) -> Image.Image:
    im = im.convert("RGBA")
    bbox = im.getbbox()
    return im.crop(bbox) if bbox else im


def fit_icon(im: Image.Image, size: int = SIZE) -> Image.Image:
    im = trim_alpha(im)
    w, h = im.size
    if w == 0 or h == 0:
        return Image.new("RGBA", (size, size), (0, 0, 0, 0))
    margin = int(size * PAD)
    inner = size - 2 * margin
    scale = min(inner / w, inner / h)
    nw, nh = max(1, int(w * scale)), max(1, int(h * scale))
    im = im.resize((nw, nh), Image.Resampling.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(im, ((size - nw) // 2, (size - nh) // 2), im)
    return canvas


def save_icon(im: Image.Image, name: str) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    fit_icon(im).save(OUT / name, "PNG")


def from_ui(ui_name: str, dest: str) -> None:
    save_icon(Image.open(UI / ui_name), dest)


def run_godot_renders() -> None:
    godot = Path("/home/ubuntu/.local/bin/godot")
    if not godot.is_file():
        godot = Path(shutil.which("godot") or "")
    if not godot.is_file():
        raise RuntimeError("Godot not found")
    cmd = [
        "xvfb-run",
        "-a",
        "-s",
        "-screen 0 512x512x24",
        str(godot),
        "--path",
        str(ROOT),
        "-s",
        "res://scripts/tools/render_item_icons.gd",
    ]
    proc = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=120)
    if proc.returncode != 0 or "RENDER_ITEM_ICONS_OK" not in proc.stdout:
        print(proc.stdout, proc.stderr, file=sys.stderr)
        raise RuntimeError("GLB icon render failed")


def main() -> None:
    run_godot_renders()

    fallbacks = {
        "icon_xiphos.png": GEAR / "xiphos_sword_0.png",
        "icon_kontos.png": GEAR / "kontos_spear_0.png",
        "icon_aspis.png": GEAR / "aspis_shield_0.png",
        "icon_tower_shield.png": GEAR / "tower_aspis_face.png",
    }
    for dest, src in fallbacks.items():
        if not (OUT / dest).is_file() and src.is_file():
            save_icon(Image.open(src), dest)

    # Game UI set (same art direction as HUD / shop).
    from_ui("icon_sword.png", "icon_bow.png")
    from_ui("icon_boot.png", "icon_leather_sandals.png")
    from_ui("icon_anvil.png", "icon_bronze_greaves.png")
    from_ui("icon_shield.png", "icon_leather_cuirass.png")
    from_ui("icon_anvil.png", "icon_bronze_thorax.png")
    from_ui("icon_laurel.png", "icon_olive_necklace.png")
    from_ui("icon_gold.png", "icon_gold_torque.png")
    from_ui("icon_gem.png", "icon_bronze_earring.png")
    from_ui("icon_gem.png", "icon_silver_earring.png")
    from_ui("icon_scroll.png", "icon_leather_bracelet.png")
    from_ui("icon_anvil.png", "icon_bronze_bracelet.png")
    from_ui("icon_skull.png", "icon_mat_wolf_pelt.png")
    from_ui("icon_gem.png", "icon_mat_boar_tusk.png")
    from_ui("icon_skull.png", "icon_mat_satyr_horn.png")
    from_ui("icon_mana.png", "icon_mat_harpy_feather.png")
    from_ui("icon_boot.png", "icon_mat_centaur_hoof.png")

    print("Built icons in", OUT)


if __name__ == "__main__":
    main()
