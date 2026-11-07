# Champion memory cinematics

Dialogue animatic for the gate scene (champion meets the witness who remembers prior world cycles).

## Assets

- `champion_memory_dialogue.srt` — burn-in subtitle timing (4:22.054).
- `scenes/*.jpg` — still frames for Ken Burns motion.

## Render

```bash
./scripts/tools/render_champion_memory_cinematic.sh
```

Default output: `assets/cinematic/champion_memory/champion_memory_animatic.mp4` (1920×1080, 30 fps, soft ambient bed, no VO).

Pass a path to write elsewhere:

```bash
./scripts/tools/render_champion_memory_cinematic.sh /tmp/out.mp4
```

Requires `ffmpeg` only.
