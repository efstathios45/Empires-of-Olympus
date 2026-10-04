# Empires-of-Olympus

Godot 4.4 Metin-style Greek MMO client: accounts, empire map, panoply,
Enter-to-chat, Minecraft-style server browser, and online host/join.

## Windows download

### Recommended (Defender-friendlier — no .exe in the zip)

**https://gofile.io/d/2HtdbODQ** — `EmpiresOfOlympus-data-only.zip`

Extract → `powershell -ExecutionPolicy Bypass -File .\GET-ENGINE.ps1`

### Full zip

**https://gofile.io/d/QX1B74q6** — `EmpiresOfOlympus-windows.zip`

Tripo mobs face the player (chest/head +Z → chase): satyr/gorgon/minotaur
`facing_plus_z`, harpy yaw 270°. Harpy arm→wing aliases removed (entangle).
`%GeneralSkeleton` bind kept; pitch-only posture (no arm dampen).

Run notes: [`docs/WINDOWS_RUN.md`](docs/WINDOWS_RUN.md)

## Build yourself

See [`README_EXPORT.md`](README_EXPORT.md) and [`.github/workflows/release.yml`](.github/workflows/release.yml).
