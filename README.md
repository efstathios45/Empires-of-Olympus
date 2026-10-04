# Empires-of-Olympus

Godot 4.4 Metin-style Greek MMO client: accounts, empire map, panoply,
Enter-to-chat, Minecraft-style server browser, and online host/join.

Hoplite class uses PS1/PSX Hoplite Chan; centaur enemies use the bone centaur.

## Windows download

### Recommended (avoids Defender exe-in-zip false positives)

**https://gofile.io/d/BgE1qK2B** — `EmpiresOfOlympus-data-only.zip`

Extract → run `powershell -ExecutionPolicy Bypass -File .\GET-ENGINE.ps1`
(pulls the official Godot 4.4.1 engine from github.com/godotengine).

### Full zip (exe + pck) — if you already allowlisted Defender

**https://gofile.io/d/PIUbZAh4** — `EmpiresOfOlympus-windows.zip`

Extract both files into the same folder, then run `EmpiresOfOlympus.exe`.

This build: enemies chase facing you; plaza NPCs use textured characters
(not flat white/brown). Run notes: [`docs/WINDOWS_RUN.md`](docs/WINDOWS_RUN.md)

## Build yourself

See [`README_EXPORT.md`](README_EXPORT.md) and [`.github/workflows/release.yml`](.github/workflows/release.yml).
