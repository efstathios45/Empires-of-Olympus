# Empires-of-Olympus

Godot 4.4 Metin-style Greek MMO client: accounts, empire map, panoply,
Enter-to-chat, Minecraft-style server browser, and online host/join.

## Windows download

### Recommended (Defender-friendlier — no .exe in the zip)

**https://gofile.io/d/Psg4KukO** — `EmpiresOfOlympus-data-only.zip`

Extract → `powershell -ExecutionPolicy Bypass -File .\GET-ENGINE.ps1`

### Full zip

**https://gofile.io/d/0BjW60KE** — `EmpiresOfOlympus-windows.zip`

This build restores the **old-exe UAL motion baseline** (meshes +
`GeneralSkeleton` import binds, no runtime retarget/posture correctors)
while keeping chat, settings, server browser, and multiplayer from the
full-game branch. Plaza NPCs use the textured UAL cast again.

Run notes: [`docs/WINDOWS_RUN.md`](docs/WINDOWS_RUN.md)

## Build yourself

See [`README_EXPORT.md`](README_EXPORT.md) and [`.github/workflows/release.yml`](.github/workflows/release.yml).
