# Empires-of-Olympus

Godot 4.4 Metin-style Greek MMO client: accounts, empire map, panoply,
Enter-to-chat, Minecraft-style server browser, and online host/join.

## Windows download

### Recommended (Defender-friendlier — no .exe in the zip)

**https://gofile.io/d/w4F0tDYs** — `EmpiresOfOlympus-data-only.zip`

Extract → `powershell -ExecutionPolicy Bypass -File .\GET-ENGINE.ps1`

### Full zip

**https://gofile.io/d/BDeCvLuO** — `EmpiresOfOlympus-windows.zip`

This build fixes the **root UAL posture bug** (sky-gaze / entangled limbs on
the old guard-style meshes): plaza uses Quaternius native Idle; UAL enemies
get a post-animation posture corrector.

Run notes: [`docs/WINDOWS_RUN.md`](docs/WINDOWS_RUN.md)

## Build yourself

See [`README_EXPORT.md`](README_EXPORT.md) and [`.github/workflows/release.yml`](.github/workflows/release.yml).
