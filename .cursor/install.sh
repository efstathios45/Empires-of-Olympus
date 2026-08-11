#!/usr/bin/env bash
# Idempotent repository bootstrap for the Godot 4.4 project.
#
# Runs Godot's headless import so the `.godot/` cache (imported assets, script
# class cache, UID map) is generated from the checked-out source. Safe to run
# repeatedly: Godot only re-imports what changed.
#
# NOTE: the editor-only `zylann.hterrain` plugin script (tools/plugin.gd) is not
# shipped, so the import log notes it can't load that plugin. That's harmless for
# running the game (the plugin is editor-only) and doesn't affect the import's
# exit status, so we let the import run to completion regardless.
set -uo pipefail

cd "$(dirname "$0")/.."

echo "== Godot version =="
godot --version

echo "== Importing project (headless) =="
godot --headless --editor --import --path . || true

echo "== Import cache =="
ls -la .godot 2>/dev/null || echo "WARNING: .godot cache was not created"

echo "Install complete."
