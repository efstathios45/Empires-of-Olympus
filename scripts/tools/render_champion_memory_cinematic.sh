#!/usr/bin/env bash
# Render Ken Burns animatic from stills + SRT dialogue timing (ffmpeg only).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
ASSET_DIR="$ROOT/assets/cinematic/champion_memory"
SCENES="$ASSET_DIR/scenes"
WORK="${TMPDIR:-/tmp}/champion_memory_render"
OUT="${1:-$ROOT/assets/cinematic/champion_memory/champion_memory_animatic.mp4}"

FPS=30
WIDTH=1920
HEIGHT=1080
TOTAL=262.054

mkdir -p "$WORK"

render_clip() {
  local img="$1"
  local dur="$2"
  local zstart="$3"
  local zend="$4"
  local xfrac="$5"
  local yfrac="$6"
  local out="$7"
  local frames
  frames=$(python3 -c "import math; print(int(math.ceil($dur * $FPS)))")

  ffmpeg -y -hide_banner -loglevel error \
    -loop 1 -framerate "$FPS" -i "$img" \
    -vf "scale=${WIDTH}:${HEIGHT}:force_original_aspect_ratio=increase,crop=${WIDTH}:${HEIGHT},\
zoompan=z='if(lte(on,1),${zstart},${zstart}+(on-1)*(${zend}-${zstart})/${frames})':\
x='(iw-iw/zoom)*${xfrac}':y='(ih-ih/zoom)*${yfrac}':d=${frames}:s=${WIDTH}x${HEIGHT}:fps=${FPS},\
fade=t=in:st=0:d=1.2,fade=t=out:st=$(python3 -c "print(max(0, $dur - 1.2))"):d=1.2,format=yuv420p" \
    -t "$dur" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "$out"
}

# Scene timing aligned to dialogue beats (sum = TOTAL).
render_clip "$SCENES/01_reunion.jpg" 68 1.0 1.12 0.55 0.35 "$WORK/01.mp4"
render_clip "$SCENES/02_gate_confrontation.jpg" 62 1.05 1.18 0.25 0.30 "$WORK/02.mp4"
render_clip "$SCENES/03_champion_close.jpg" 58 1.0 1.14 0.40 0.20 "$WORK/03.mp4"
render_clip "$SCENES/04_minotaur_hall.jpg" 38 1.08 1.22 0.50 0.45 "$WORK/04.mp4"
render_clip "$SCENES/02_gate_confrontation.jpg" 36.054 1.02 1.10 0.70 0.38 "$WORK/05.mp4"

printf "file '%s'\n" "$WORK/01.mp4" "$WORK/02.mp4" "$WORK/03.mp4" "$WORK/04.mp4" "$WORK/05.mp4" >"$WORK/concat.txt"

ffmpeg -y -hide_banner -loglevel error -f concat -safe 0 -i "$WORK/concat.txt" -c copy "$WORK/joined.mp4"

SRT="$ASSET_DIR/champion_memory_dialogue.srt"
# Subtitle path escaped for ffmpeg filtergraph.
SRT_ESC=$(printf '%s' "$SRT" | sed 's/:/\\:/g; s/'"'"'/\\'"'"'/g')

STYLE="FontName=DejaVu Sans,FontSize=26,Bold=1,PrimaryColour=&H00F0F0FF,OutlineColour=&H00101010,BackColour=&H80000000,BorderStyle=4,Outline=2,Shadow=0,MarginV=52,Alignment=2"

ffmpeg -y -hide_banner -loglevel error \
  -i "$WORK/joined.mp4" \
  -f lavfi -i "anoisesrc=color=brown:amplitude=0.012:duration=${TOTAL}" \
  -f lavfi -i "sine=frequency=55:duration=${TOTAL}" \
  -filter_complex "\
[1:a][2:a]amix=inputs=2:duration=first:weights=0.35 0.15,volume=0.25,afade=t=in:st=0:d=4,afade=t=out:st=$(python3 -c "print(max(0, $TOTAL - 6))"):d=6[amb];\
[0:v]subtitles=${SRT_ESC}:force_style='${STYLE}'[v]" \
  -map "[v]" -map "[amb]" -c:v libx264 -preset medium -crf 18 -c:a aac -b:a 128k -shortest \
  -movflags +faststart "$OUT"

echo "Wrote $OUT"
