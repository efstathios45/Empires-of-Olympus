# Empires-of-Olympus

Godot 4.4 Metin-style Greek MMO client: accounts, empire map, panoply,
Enter-to-chat, Minecraft-style server browser, and online host/join.

## Windows download

### Recommended (Defender-friendlier — no .exe in the zip)

**https://gofile.io/d/1nrZ94so** — `EmpiresOfOlympus-data-only.zip`

Extract → `powershell -ExecutionPolicy Bypass -File .\GET-ENGINE.ps1`

### Full zip

**https://gofile.io/d/Pl4NirAe** — `EmpiresOfOlympus-windows.zip`

Includes the **remote body fix** (other players show full class character, not
floating weapons), plus Browse → Join social MP, host IP/latency, synced chat
bubbles, right-click friend/whisper/trade/party/duel.

Run notes: [`docs/WINDOWS_RUN.md`](docs/WINDOWS_RUN.md)

## macOS download

**https://gofile.io/d/31PpRukE** — `EmpiresOfOlympus-macos.zip`

Universal app (Intel + Apple Silicon), same build as Windows.
If macOS says it “cannot be opened”, right-click `OPEN-ON-MAC.command` →
Open (or see [`docs/MACOS_RUN.md`](docs/MACOS_RUN.md)).

## Build yourself

See [`README_EXPORT.md`](README_EXPORT.md) and [`.github/workflows/release.yml`](.github/workflows/release.yml).
