# Empires-of-Olympus

Godot 4.4 Metin-style Greek MMO client: accounts, empire map, panoply,
Enter-to-chat, Minecraft-style server browser, and online host/join.

## Windows download

### Recommended (Defender-friendlier — no .exe in the zip)

**https://gofile.io/d/YjZsm1mo** — `EmpiresOfOlympus-data-only.zip`

Extract → `powershell -ExecutionPolicy Bypass -File .\GET-ENGINE.ps1`

### Full zip

**https://gofile.io/d/23r0SiSB** — `EmpiresOfOlympus-windows.zip`

This build adds **multiplayer social** on the peer-save / party baseline:
Browse → Join → account; host-only peer IP + latency; class-correct remote
characters (no pink stub); synced chat bubbles; right-click friend / whisper /
trade / party (blue) / duel (15% gold + random item).

Run notes: [`docs/WINDOWS_RUN.md`](docs/WINDOWS_RUN.md)

## macOS download

**https://gofile.io/d/CflPpcoX** — `EmpiresOfOlympus-macos.zip`

Universal app (Intel + Apple Silicon), same social multiplayer build as Windows.
If macOS says it “cannot be opened”, right-click `OPEN-ON-MAC.command` →
Open (or see [`docs/MACOS_RUN.md`](docs/MACOS_RUN.md)).

## Build yourself

See [`README_EXPORT.md`](README_EXPORT.md) and [`.github/workflows/release.yml`](.github/workflows/release.yml).
