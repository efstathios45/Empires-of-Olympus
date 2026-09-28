# Accounts & saves

**Default today: local-only.** Username/password + a save file on this PC.
Cross-device sync and multiplayer persistence are stubbed and documented below.

## Player flow

1. Title → **Register** / **Sign In** (or **Play Guest**)
2. Esc → **Save** (autosave ~every 45s when signed in)
3. Title → **Continue** loads `user://saves/<user>.json`

Guest play does not persist.

## Data shape (keep this stable)

`GameState.to_save_dict()` / `apply_save_dict()` is the **single snapshot** for:

- empire, class, name, level, xp, gold, refine
- bag + equipped slots
- quests / clan / optional `pos`

Anything that needs to survive a session (or travel between clients) must go
through this dict — not ad-hoc globals.

## Files

| Path | Purpose |
|------|---------|
| `user://accounts.json` | Salted password hashes + display names |
| `user://saves/<user>.json` | Latest run snapshot |
| `user://session.json` | Remembered login on this device |
| `scripts/autoloads/account_system.gd` | Auth + save/load (+ optional cloud) |
| `cloud_sync/` | Optional HTTP sync API (off by default) |

## Enabling shared / cloud later

1. Host `cloud_sync/` (see that folder’s README / Dockerfile).
2. In `account_system.gd`: set `CLOUD_ENABLED = true` and `sync_url` (or write
   `user://sync_url.txt` with the API root).
3. Re-ship the client. Register/login will also hit `/v1/register` + `/v1/login`;
   saves will PUT/GET `/v1/save`.

Conflict rule already implied by the API: **last write wins** via `saved_at`.
For real multiplayer you will want server authority (below).

## Advice: multiplayer-ready persistence

When you add shared worlds / parties, treat the local JSON as a **client cache**,
not the source of truth.

Recommended shape:

1. **Authoritative game server** (Godot dedicated, or custom) owns:
   - character rows (same fields as `to_save_dict`)
   - world mutables you care about (chests opened, stones destroyed, etc.)
2. **Auth**: keep username/password (or move to OAuth later). Issue a session
   token; every save/load goes over that token.
3. **Protocol**:
   - login → token + character list
   - enter world → server spawns you from DB snapshot
   - periodic / on-checkpoint → client sends *deltas* or full snapshot;
     server validates (gold can’t jump illegally, etc.) and stores
   - disconnect → server writes final snapshot
4. **Reuse `to_save_dict()`** as the payload schema so UI and combat code do not
   fork. Version it with `"v": N` and migrate in `apply_save_dict`.
5. **Do not** trust the client for inventory/gold in multiplayer — validate on
   the server. Local-only mode can keep trusting the file.
6. **Optional bridge**: keep `cloud_sync/` as a thin “solo cloud save” service;
   multiplayer should be a real game server that also persists characters.

`AccountSystem.cloud_available()` gates the HTTP paths so solo builds stay
offline-friendly until you flip the flag.
