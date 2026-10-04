# Empires-of-Olympus

Godot 4.4 Metin-style Greek MMO client: accounts, empire map, panoply,
Enter-to-chat, Minecraft-style server browser, and online host/join.

Hoplite class uses PS1/PSX Hoplite Chan; centaur enemies use the bone centaur.

## Windows download

Defender often false-positives **any zip that contains a Godot `.exe`** from
file hosts. Prefer one of these:

### A) Data-only zip (recommended if Defender flagged the full zip)

**https://gofile.io/d/BafoP5Nd** — `EmpiresOfOlympus-data-only.zip`

Contains `EmpiresOfOlympus.pck` + `GET-ENGINE.ps1` (no `.exe` inside).
Run the script once; it pulls the official Godot 4.4.1 engine from
`github.com/godotengine` and verifies SHA-256.

### B) Full zip (exe + pck) — GitHub Release (repo collaborators)

If you can log into GitHub on this private repo:

**https://github.com/efstathios45/Empires-of-Olympus/releases/tag/v0.9.1-windows**

### If Defender still quarantines

Windows Security → Protection history → **Allow on this device**.
Details / hashes: [`docs/WINDOWS_RUN.md`](docs/WINDOWS_RUN.md)

## Build yourself

See [`README_EXPORT.md`](README_EXPORT.md) and [`.github/workflows/release.yml`](.github/workflows/release.yml).
