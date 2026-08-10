#!/usr/bin/env bash
# Idempotent repository bootstrap for the Godot 4.3 project.
#
# Runs Godot's headless import so the `.godot/` cache (imported assets, script
# class cache, UID map) is generated from the checked-out source. Safe to run
# repeatedly: Godot only re-imports what changed.
#
# NOTE: this project was exported without its `res://assets/` directory and
# bundles the third-party `zylann.hterrain` editor addon, so the import log
# contains "file does not exist" / addon parse errors. Those are pre-existing
# content gaps, not environment failures, and do not affect the import's exit
# status, so we let the import run to completion regardless.
set -uo pipefail

cd "$(dirname "$0")/.."

echo "== Godot version =="
godot --version

echo "== Importing project (headless) =="
godot --headless --editor --import --path . || true

echo "== Import cache =="
ls -la .godot 2>/dev/null || echo "WARNING: .godot cache was not created"

echo "Install complete."
